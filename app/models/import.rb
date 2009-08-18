class Import < ActiveRecord::Base
  
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
  aasm_state :accepted, :enter => :accept_import
  aasm_state :rejected, :enter => :reject_import
  
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
    logger.debug("\n=== Notifiy User - #{self.id}\n\n\n")
    
    # @TODO: Email should send via delayed job?
    Notifier.deliver_import_review_notification(self.user, self.id)
  end

  def accept_import
    self.send_later(:process_accepted_import)
  end
  
  def process_accepted_import
    logger.debug("\n=== Accepted Import - #{self.id}\n\n")
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
    logger.debug("\n=== Rejected Import - #{self.id}\n\n")
    logger.debug("\n* Destroying Import Works - #{self.works_added.inspect}\n\n")
    
    self.works_added.each do |work_added|
      work = Work.find_by_id(work_added)
      work.destroy
    end
    
    self.works_added = []
    
    # Delete Import -- no longer necessary?
    # Return success_path?
    # 1. Go to root_path -- general imports, flash success
    # 2. Go to person_path(@person) -- person imports, flash success
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
          logger.error("Citations could not be parsed as the character encoding could not be determined or could not be converted to UTF-8.\n")

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
    if pcites.nil? || pcites.empty?
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
      logger.debug "#{attr_hashes.size} Attr Hashes: #{attr_hashes.inspect}\n\n\n"

      # Make sure there is data in the Attribute Hash
      return nil if attr_hashes.nil?
      
      # Now, actually *create* these works in database
      attr_hashes.map { |h|
       
        # Initialize the Work
        klass = h[:klass]
      
        # Are we working with a legit SubKlass?
        klass = klass.constantize
        if klass.superclass != Work
          raise NameError.new("#{klass_type} is not a subclass of Work") and return
        end
      
        work = klass.new
      
        ###
        # Setting WorkNameStrings
        ###
        work_name_strings = h[:work_name_strings]
        work.work_name_strings = work_name_strings
      
        #If we are adding to a person, pre-verify that person's contributorship
        work.preverified_person = person if person
    
        ###
        # Setting Publication Info, including Publisher
        ###
        issn_isbn = h[:issn_isbn]
        publication_info = Hash.new
        publication_info = {:name => h[:publication], 
                                    :issn_isbn => issn_isbn,
                                    :publisher_name => h[:publisher]}

        # If publication[:name] is nothing and work type is ConferenceProceeding
        # - Make title_secondary publication name

        if publication_info[:name].nil? || publication_info[:name].empty?
          if klass_type = "ConferenceProceeding"
            publication_info[:name] = h[:title_secondary]
          end
        end

        work.publication_info = publication_info
    
        # Very minimal validation -- just check that we have a title
        if h[:title_primary].nil? or h[:title_primary] == ""
          self.import_errors[:missing_title] = "We couldn't find a title for at least one work...you may want to verify everything imported properly!"
          
          logger.warn("The following work did not have a title and could not be imported!\n #{h}\n\n")
          logger.warn("End Work \n\n")
        else
     
          ###
          # Setting Keywords
          ###
          work.keyword_strings = h[:keywords]

          # Clean the hash of non-Work table data
          # Cleaning will prepare the hash for ActiveRecord insert
          h.delete(:klass)
          h.delete(:work_name_strings)
          h.delete(:publisher)
          h.delete(:publication)
          h.delete(:publication_place)
          h.delete(:issn_isbn)
          h.delete(:keywords)
          h.delete(:source)
          # @TODO add external_systems to work import
          h.delete(:external_id)
          
          #save remaining hash attributes
          work.attributes=h
          work.save_and_set_for_index
   
          # current user automatically gets 'admin' permissions on work
          # (only if he/she doesn't already have that role on the work)
          work.accepts_role 'admin', self.user
        
          #add to batch of works created
          works_added << work.id
        end #end if no title
      }
      
      #index everything in Solr
      Index.batch_index
      
    # This error occurs if the works were parsed, but some bad data
    # was entered which caused an error to occur when saving the data
    # to the database.
    rescue Exception => e
      # remove anything already added to the database (i.e. rollback ALL changes)
      unless works_added.nil?
        works_added.each do |work_id|
          work = Work.find(work_id)
          work.destroy unless work.nil?     
        end
      end

      #re-raise this exception to create()...it will handle logging the error
      self.import_errors[:exception] = e
      self.save
      self.review!
    end
   
    # At this point, some or all of the works were saved to the database successfully.
    # return works_added, errors
    self.works_added = works_added
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