class Import < ActiveRecord::Base
  cattr_reader :per_page
  @@per_page = 10
  
  
  # ActiveRecord Attributes
  attr_protected :state
  serialize :works_added
  serialize :import_errors
  
  # ActiveRecord Associations
  belongs_to :user

  has_one :import_file, :as => :asset,
    :dependent => :delete
    
  # ActiveRecord Callbacks
  def after_create
    self.process!
  end

  # Acts As State Machine
  include AASM
  aasm_column :state
  aasm_initial_state :recieved

  aasm_state :recieved
  aasm_state :processing, :enter => :queue_import
  aasm_state :reviewable, :enter => :notify_user
  aasm_state :accepted,   :enter => :accept_import
  aasm_state :rejected,   :enter => :reject_import
  
  aasm_event :process do
    transitions :to => :processing, :from => :recieved
  end

  aasm_event :review do
    transitions :to => :reviewable, :from => :processing
  end
  
  aasm_event :accept do
    transitions :to => :accepted, :from => :reviewable
  end
  
  aasm_event :reject do
    transitions :to => :rejected, :from => :reviewable
  end
   
  def notify_user
    logger.debug("\n=== Notifiy User - #{self.id} ===\n\n\n")
    
    # @TODO: Email should send via delayed job?
    Notifier.deliver_import_review_notification(self.user, self.id)
  end

  def accept_import
    self.send_later(:process_accepted_import)
  end
  
  def process_accepted_import
    logger.debug("\n=== Accepted Import - #{self.id} ===\n\n")
    works = Work.find(:all, :conditions => ["id in (?)", self.works_added])
    
    # Create unverified contributorships for each non-duplicate work
    works.each{|w| w.create_contributorships }
    
    # If import was for a Person, auto-verify the contributorships
    if self.person_id
      person = Person.find(person_id)
      logger.debug("\n\n\n* Auto-verify contributorships - #{self.person_id}\n\n")
      
      # Find Contributorships, set to verified.
      contributorhips = Array.new
      works.each do |work| 
        contributorship = Contributorship.find_or_create_by_work_id_and_person_id(work.id, self.person_id)
        contributorhips << contributorship
      end
      
      contributorhips.each{ |c| 
        c.verify_contributorship
        c.work.save_and_set_for_index_without_callbacks
      }
      
      logger.debug("\n\n\n* Batch indexing import - #{self.person_id}\n\n")
      Index.batch_index
    
      #Delayed Job - Update scoring hash for Person
      person.send_later(:queue_update_scoring_hash)
    end
  end
  
  def reject_import
    logger.debug("\n=== Rejected Import - #{self.id} ===\n\n")
    logger.debug("\n* Destroying Import Works")

    self.works_added.each do |work_added|
      work = Work.find_by_id(work_added)
      logger.debug("\n- Work: #{work.id}") if work
      work.send_later(:destroy) if work
    end
    
    self.works_added = []
  end

  ###
  # ===== Import Object Methods =====
  ### 
  
  # Add Import to Delayed Job queue
  def queue_import
    self.send_later(:batch_import)
  end
  
  # Process Batch Import
  def batch_import
    # CMess helps guess encoding of uploaded text files
    require 'cmess/guess_encoding'
    
    logger.debug("\n\n==== Staring Batch Import ==== \n\n")
    
    # Initialize an array of all the works we create in the batch
    self.works_added = Array.new
    
    # Initialize a Hash of all the errors encountered in the batch
    self.import_errors = Hash.new
    
    # Are we importing for a person?
    if self.person_id
      person = Person.find_by_id(self.person_id)
      logger.debug("* Person - person.display_name \n\n")
    end
    
    # Step: 1 -- Read the data
    begin       
      str = "#{RAILS_ROOT}/public#{self.import_file.public_filename}"
      if str.respond_to? :read
        str = str.read
      elsif File.readable?(str)
        str = File.read(str)
      end
     
      #Convert string to Unicode, if it's not already Unicode
      unless str.is_utf8?

        # Guess the character encoding
        encoding = CMess::GuessEncoding::Automatic.guess(str)        
        logger.debug("\n* Guessed Encoding: #{encoding}")
       
        # As long as encoding could be guessed, try to convert to UTF-8
        unless encoding.nil? or encoding.empty? or encoding==CMess::GuessEncoding::Encoding::UNKNOWN
          # Convert to one big UTF-8 string
          str =Iconv.iconv('UTF-8', encoding, str).to_s
        else
          # Log an error...this file has a character encoding we cannot handle!
          logger.error("\nCitations could not be parsed as the character encoding could not be determined or could not be converted to UTF-8.\n")

          #return nothing, which will inform user that file format was invalid
          self.import_errors[:invalid_file_format] = "Citations could not be parsed as the character encoding could not be determined or could not be converted to UTF-8."
          self.save
          self.review!
          return
        end
      end
     
    rescue Exception =>e
      #re-raise this exception to create()...it will handle logging the error
      self.import_errors[:exception] = e
      self.save
      self.review!
      return
    end
    
    # Init: Parser and Importer
    p = CitationParser.new
    i = CitationImporter.new

    # (2) Parse the data using CitationParser plugin
    begin
      #Attempt to parse the data
      pcites = p.parse(str)
    #Rescue any errors in parsing
    rescue Exception =>e
      #re-raise this exception to create()...it will handle logging the error
      self.import_errors[:exception] = e
      self.save
      self.review!
      return
    end
        
    # @TODO: Check to make sure there were not errors while parsing the data.
    #No citations were parsed
    if pcites.blank?
      logger.debug("\n* Unsupported file format!\n\n")
      self.import_errors[:no_parsed_citations] = "The format of the input was unrecognized or unsupported.<br/><strong>Supported formats include:</strong> RIS, MedLine and Refworks XML.<br/>In addition, if you are uploading a text file, it should use UTF-8 character encoding."
      logger.debug("\n* Before save: #{self.inspect}\n\n")
      self.save
      logger.debug("\n* After save: #{self.inspect}\n\n")
      self.review!
      logger.debug("\n* After review: #{self.inspect}\n\n")
      return
    end

    logger.debug("\n\nParsed Citations: #{pcites.size}\n\n")
    
    # (3) Import the data using CitationImporter Plugin
    begin
      # Map Import hashes
      attr_hashes = i.citation_attribute_hashes(pcites)
      logger.debug "\n#{attr_hashes.size} Attr Hashes: #{attr_hashes.inspect}\n\n\n"

      # Make sure there is data in the Attribute Hash
      return nil if attr_hashes.nil?
      
      # Now, actually *create* these works in database
      attr_hashes.each do |h|
     
        work, error = Work.create_from_hash(h)

        if error.nil?
          #add to batch of works created
          self.works_added << work
        else
          #error = truncate(error) if error
          self.import_errors[:import_error] = Array.new unless self.import_errors[:import_error]
          self.import_errors[:import_error] << "<em>#{h[:title_primary]}</em> could not be imported. #{error}<br/>"
        end
        
      end
      
      #index everything in Solr
      Index.batch_index
      
    # This error occurs if the works were parsed, but some bad data
    # was entered which caused an error to occur when saving the data
    # to the database.
    rescue Exception => e
      # remove anything already added to the database (i.e. rollback ALL changes)
      unless self.works_added.blank?
        self.works_added.each do |work_id|
          work = Work.find(work_id)
          work.destroy unless work.nil?     
        end
      end

      #re-raise this exception to create()...it will handle logging the error
      self.import_errors[:exception] = e.message
    end
   
    # At this point, some or all of the works were saved to the database successfully.
    # return works_added, errors
    self.save
    
    # Trigger AASM reviewable event
    # Email will be sent to User
    self.review!
  end
  
  def name_string_work_count
    # Initialize hash of name_strings
    name_strings = Hash.new
    works = Array.new
    self.works_added.each do |work_id|
      works << Work.find_by_id(work_id)
    end

    works.each do |work|
      work.name_strings.each do |ns|
        name_strings[ns.name] = {} # Init empty Hash for each name_string
        name_strings[ns.name][:id] = ns.id
        name_strings[ns.name][:works] = [] # Init empty works Array for each name_string
      end
    end
    
    works.each do |work|
      work.name_strings.each do |ns|
        name_strings[ns.name][:works] << work.id
      end
    end
    
    return name_strings
  end
end