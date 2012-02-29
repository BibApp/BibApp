require 'string_methods'
class Import < ActiveRecord::Base
  cattr_reader :per_page
  @@per_page = 10

  # ActiveRecord Attributes
  attr_protected :state
  serialize :works_added
  serialize :import_errors

  # ActiveRecord Associations
  belongs_to :user
  belongs_to :person

  has_one :import_file, :as => :asset, :dependent => :destroy

  after_create :after_create_actions

  # ActiveRecord Callbacks
  def after_create_actions
    self.process!
  end

  # Acts As State Machine
  include AASM
  aasm :column => :state do
    state :received, :initial => true
    state :processing, :after_enter => :queue_import
    state :reviewable, :after_enter => :notify_user
    state :accepted, :after_enter => :accept_import
    state :rejected, :after_enter => :reject_import
    event :process do
      transitions :to => :processing, :from => :received
    end
    event :review do
      transitions :to => :reviewable, :from => :processing
    end
    event :accept do
      transitions :to => :accepted, :from => :reviewable
    end
    event :reject do
      transitions :to => :rejected, :from => :reviewable
    end
  end

  def notify_user
    logger.debug("\n=== Notify User - #{self.id} ===\n\n\n")
    current_locale = I18n.locale
    I18n.locale = self.user.default_locale
    Notifier.import_review_notification(self).deliver
    I18n.locale = current_locale
  end

  def accept_import
    self.delay.process_accepted_import
  end

  def process_accepted_import
    logger.debug("\n=== Accepted Import - #{self.id} ===\n\n")
    works = Work.where("id in (?)", self.works_added)

    # Create unverified contributorships for each non-duplicate work
    works.each { |w| w.create_contributorships }

    # If import was for a Person, auto-verify the contributorships
    if self.person_id
      person = Person.find(person_id)
      logger.debug("\n\n\n* Auto-verify contributorships - #{self.person_id}\n\n")

      # Find Contributorships, set to verified.
      contributorships = works.collect do |work|
        Contributorship.find_or_create_by_work_id_and_person_id(work.id, self.person_id)
      end

      contributorships.each do |c|
        c.verify_contributorship
        c.work.set_for_index_and_save
      end

      logger.debug("\n\n\n* Batch indexing import - #{self.person_id}\n\n")
      Index.batch_index

      #Delayed Job - Update scoring hash for Person
      person.delay.queue_update_scoring_hash
    end
  end

  def reject_import
    logger.debug("\n=== Rejected Import - #{self.id} ===\n\n")
    logger.debug("\n* Destroying Import Works")

    self.works_added.each do |work_added|
      work = Work.find_by_id(work_added)
      logger.debug("\n- Work: #{work.id}") if work
      work.delay.destroy if work
    end

    self.works_added = []
  end

###
# ===== Import Object Methods =====
###

# Add Import to Delayed Job queue
  def queue_import
    self.delay.batch_import
  end

# Process Batch Import
  def batch_import
    return unless self.state == 'processing'
    self.transaction do
      logger.debug("\n\n==== Starting Batch Import ==== \n\n")

      # Initialize an array of all the works added and hash of errors encountered in the batch
      self.works_added = Array.new
      self.import_errors = Hash.new

      # Init: Parser and Importer
      citation_parser = CitationParser.new
      citation_importer = CitationImporter.new

      # Step: 1 -- Read the data
      begin
        begin
          str = StringMethods.ensure_utf8(self.read_import_file)
        rescue EncodingException => e
          self.import_errors[:invalid_file_format] = "Citations could not be parsed as the character encoding could not be determined or could not be converted to UTF-8."
          raise e
        end

        parsed_citations = citation_parser.parse(str)
      rescue Exception => e
        self.import_errors[:exception] = e
        self.save_and_review!
        return
      end

      if parsed_citations.blank?
        self.import_errors[:no_parsed_citations] = <<-MESSAGE
        The format of the input was unrecognized or unsupported.
        <br/><strong>Supported formats include:</strong> RIS, MedLine and Refworks XML.<br/>
        In addition, if you are uploading a text file, it should use UTF-8 character encoding.
        MESSAGE
        self.save_and_review!
        return
      end

      begin
        #import citations
        attr_hashes = citation_importer.citation_attribute_hashes(parsed_citations)

        # Make sure there is data in the Attribute Hash
        return nil if attr_hashes.nil?

        #create works and reindex
        create_works_from_attribute_hashes(attr_hashes)
        Index.batch_index

      rescue Exception => e
        self.import_errors[:exception] = e.message
      end

      # At this point, some or all of the works were saved to the database successfully.
      self.save_and_review!
    end
  end

  def save_and_review!
    self.save
    self.review!
  end

  def read_import_file
    File.read(self.import_file.absolute_path)
  end

# Create works in database. Use a transaction to rollback if there is an error, allowing error to propagate
  def create_works_from_attribute_hashes(attr_hashes)
    self.transaction do
      attr_hashes.each do |h|
        begin
          work = Work.create_from_hash(h, false)
          if work.errors.blank?
            #add to batch of works created
            self.works_added << work.id
          else #validation problem
            self.import_errors[:import_error] ||= Array.new
            self.import_errors[:import_error] << "<em>#{h[:title_primary]}</em> could not be imported. #{work.errors.to_s}<br/>"
          end
        rescue Exception => e
          #actual exception
          self.import_errors[:import_error] ||= Array.new
          self.import_errors[:import_error] << "<em>#{h[:title_primary]}</em> could not be imported. #{e.to_s}<br/>"
        end
      end
    end
  end

  def name_string_work_count
    works = self.works_added.collect { |work_id| Work.find_by_id(work_id) }.compact

    # Initialize hash of name_strings
    name_strings = Hash.new

    works.each do |work|
      work.name_strings.each do |ns|
        name_strings[ns.name] ||= {:id => ns.id, :works => []}
        name_strings[ns.name][:works] << work.id
      end
    end

    return name_strings
  end

end
