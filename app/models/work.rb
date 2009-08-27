class Work < ActiveRecord::Base
  
  acts_as_authorizable  #some actions on Works require authorization
  
  cattr_accessor :current_user
  
  # Information about a 'pre-verified' Contributorship
  # for a specific Person in the system
  # (This occurs when adding a Work directly to a Person).
  cattr_accessor :preverified_person
 
  serialize :scoring_hash
  
  #### Associations ####
  belongs_to :publication
  belongs_to :publisher
  
  has_many :name_strings, :through => :work_name_strings,
    :order => "position"
  
  has_many :work_name_strings, :order => "position",
    :dependent => :delete_all
  
  has_many :people,
    :through => :contributorships,
    :conditions => ["contributorship_state_id = ?", 2]
    
  has_many :contributorships,
    :dependent => :delete_all
  
  has_many :keywords, :through => :keywordings
  has_many :keywordings,
    :dependent => :delete_all
  
  has_many :taggings, :as => :taggable, :dependent => :delete_all
  has_many :tags, :through => :taggings
  has_many :users, :through => :taggings

  has_many :external_system_uris
  
  has_many :attachments, :as => :asset
  belongs_to :work_archive_state

  #### Named Scopes ####
  #Various Work Statuses
  named_scope :in_process, :conditions => ["work_state_id = ?", 1]
  named_scope :duplicate, :conditions => ["work_state_id = ?", 2]
  named_scope :accepted, :conditions => ["work_state_id = ?", 3]
  
  #Various Work Archival Statuses
  named_scope :ready_to_archive, :conditions => ["work_archive_state_id = ?", 2]
  named_scope :archived, :conditions => ["work_archive_state_id = ?", 3]
 
  # Work flagged for batch indexing
  named_scope :to_batch_index, :conditions => ["batch_index = ?", 1] do
    # Method to mark all these Works as 'indexed'
    # by resetting 'batch_index' flag to false
    def indexed
      each do |work|
        work.batch_index=0
        work.save_without_callbacks
      end
    end
  end
  
  #Various Work Contribution Statuses
  named_scope :unverified, :include => :contributorships, :conditions => ["contributorships.contributorship_state_id = ?", 1]
  named_scope :verified, :include => :contributorships,:conditions => ["contributorships.contributorship_state_id = ?", 2]
  named_scope :denied, :include => :contributorships, :conditions => ["contributorships.contributorship_state_id = ?", 3]
  named_scope :visible, :include => :contributorships, :conditions => ["contributorships.hide = ?", false]
  
  #### Callbacks ####
  before_validation_on_create :set_initial_states

  # After Create only
  # (Note: after create callbacks *must* be placed in Work model, 
  #  for faux-accessors to work properly)
  def after_create
    create_work_name_strings
    create_keywords
    create_tags
    
    #save any changes to work
    self.save_without_callbacks
  end
  
  # NOTE: after_save callback is in 'work_observer.rb',
  # to ensure it is called *before* after_save in 'index_observer.rb'
  # (This ensures work is updated completely *before* re-indexing)
  
  # Not a true callback, but this method is called by
  # 'after_save' callback in 'work_observer.rb' in order
  # to update all work information after a work has been saved.
  def update_work
    # The Work object needs to be reloaded into memory,
    # otherwise the faux-accessors will *not* be available in the
    # after_save callbacks.
    self.reload
    
    #update dynamic database fields
    update_scoring_hash
    update_archive_state
    update_machine_name
    update_authorities
    
    #re-check for duplicate works (after all updates have completed)
    deduplicate
    
    #Update all contributorships for this work (re-create them)
    #NB: This -has- to happen after deduplicate, because contributorships
    #cannont be assigned to duplicates
    create_contributorships
  end
  
  #### Serialization ####
  serialize :serialized_data

 
  ##### Work State Methods #####
  def in_process?
    return true if self.work_state_id==1
  end
  
  def is_in_process
    self.work_state_id=1
  end
  
  def duplicate?
    return true if self.work_state_id==2
  end
  
  def is_duplicate
    self.work_state_id=2
  end
  
  def accepted?
    return true if self.work_state_id==3
  end
  
  def is_accepted
    self.work_state_id=3
  end
  
  # The field for work status in BibApp's Solr Index
  def self.solr_status_field
    return "status:"
  end
  
  # The Solr filter for accepted works...this is used by default, as
  # we don't want incomplete works to normally appear in BibApp
  def self.solr_accepted_filter
    return solr_status_field + "3"  # 3 = accepted
  end
  
  # The Solr filter for duplicate works...these works are normally
  # hidden by BibApp, except to administrators
  def self.solr_duplicate_filter
    return solr_status_field + "2"  # 2 = duplicate
  end
  
  
  ##### Work Archival State Methods #####
  def init_archive_status
    self.work_archive_state_id=1
  end
  
  def ready_to_archive?
    return true if self.work_archive_state_id==2
  end
  
  def is_ready_to_archive
    self.work_archive_state_id=2
  end
  
  def archived?
    return true if self.work_archive_state_id==3
  end
  
   def is_archived
    self.work_archive_state_id=3
  end

  
  ########## Methods ##########
  # Rule #1: Comment H-E-A-V-I-L-Y
  # Rule #2: Include @TODOs

  # List of all currently enabled Work Types
  def self.types
    # @TODO: Add each work subklass to this array
    # "Journal Article", 
    # "Conference Proceeding", 
    # "Book"
    # more...   	    			  
    types = [
      "Artwork",
      "Book (Section)",
      "Book (Whole)",
      "Book Review",
      "Composition",
      "Conference Paper",
      "Conference Poster",
      "Conference Proceeding (Whole)",
      "Dissertation / Thesis",
      "Exhibition",
      "Grant",
      "Journal (Whole)",
      "Journal Article",
      "Monograph",
      "Patent",
      "Performance",
      "Presentation / Lecture",
      "Recording (Moving Image)",
      "Recording (Sound)",
      "Report",
      "Web Page",
      "Generic"
      ]  
  end

  def self.type_to_class(type)
      t = type.gsub(" ", "") #remove spaces
      t.gsub!("/", "") #remove slashes
      t.gsub!(/[()]/, "") #remove any parens
      t.constantize #change into a class
  end
  
  # Creates a new work from an attribute hash
  def self.create_from_hash(h)

    begin
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
      # We need to get creator and contributor roles
      # from the subklasses
      # (e.g., for Artwork creator=>Artist, contributor=>Curator)
      ###
      work_name_strings = Array.new
      
      h[:work_name_strings].each do |wns|
        role = wns[:role]
        if role == 'Author'
          role = klass.creator_role
        elsif role == 'Editor'
          role = klass.contributor_role
        end
        work_name_strings << {:name=>wns[:name], :role=>role}
      end
      
      work.work_name_strings = work_name_strings

      #If we are adding to a person, pre-verify that person's contributorship
      person = Person.find(h[:person_id]) if h[:person_id]
      work.preverified_person = person if person

      ###
      # Setting Publication Info, including Publisher
      ###
      issn_isbn = h[:issn_isbn]
      publisher = h[:publisher]

      case klass.to_s
      when 'BookWhole', 'Monograph', 'JournalWhole', 'ConferenceProceedingWhole'
        publication = h[:title_primary] ? h[:title_primary] : 'Unknown'
      when 'BookSection', 'ConferencePaper', 'ConferencePoster', 'PresentationLecture', 'Report'
        publication = h[:title_secondary] ? h[:title_secondary] : 'Unknown'
      when 'JournalArticle', 'BookReview', 'Performance', 'RecordingSound', 'RecordingMovingImage', 'Generic'
        publication = h[:publication] ? h[:publication] : 'Unknown'
      else
        publication = nil
      end

      if publication == 'Unknown'
        if issn_isbn.blank?
          publication = nil
        else
          publication = "Unknown (#{issn_isbn})"
        end
      end

      publication_info = Hash.new
      publication_info = {:publication_name => publication,
                          :issn_isbn => issn_isbn,
                          :publisher_name => publisher}

      work.publication_info = publication_info

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
      h.delete(:issn_isbn)
      h.delete(:keywords)
      h.delete(:source)
      # @TODO add external_systems to work import
      h.delete(:external_id)

      #save remaining hash attributes
      work.attributes=h
      saved = work.save

    rescue Exception => e
      return nil, e
    end

    if saved
      return work.id, nil
    else
      return nil, "Validation Error: Primary Title is missing."
    end
  end

  
  # Deduplication: deduplicate Work records on save
  def deduplicate
    logger.debug("\n\n===DEDUPLICATE===\n\n")

    #Find all possible dupe candidates from Solr
    dupe_candidates = Index.possible_accepted_duplicate_works(self)
    logger.debug("\nDuplicates: #{dupe_candidates.size}")

    #Check if any duplicates found.
    #@TODO: Be smarter about this...first in probably shouldn't always win
    if dupe_candidates.empty?
      self.is_accepted
    #Only mark as duplicate if this work wasn't previously accepted 
    elsif !self.accepted? 
      self.is_duplicate
    end
    self.save_without_callbacks
    
    #@TODO: Is there a way that we can calculate the *canonical best*
    # version of a work? We've tried this in the past, but we need to do 
    # it in a better way (e.g.  we don't end up accidently re-marking things as
    # dupes that have previously been determined to not be dupes by a human)
  end
  
  def save_without_callbacks
    update_without_callbacks
  end
  
  def save_and_set_for_index_without_callbacks
    self.batch_index = 1
    self.save_without_callbacks
  end
  
  def save_and_set_for_index
    self.batch_index = 1
    self.save
  end

  # Finds year of publication for this work
  def year
    if publication_date != nil
      publication_date.year
    else
      nil
    end
  end

  # Returns the 
  def name
    return self.to_s
  end
  
  # Initializes an array of Keywords
  # and saves them to the current Work
  # Arguments:
  #  * array of keyword strings
  def keyword_strings=(keyword_strings)
    #default to empty array of keywords
    keyword_strings ||= []  
          
    #Initialize keywords
    keywords = Array.new
    keyword_strings.to_a.uniq.each do |add|
      keywords << Keyword.find_or_initialize_by_name(add)
    end
    
    #save or update Work
    self.keywords = keywords   
  end 
  
  # Initializes an array of Tags
  # and saves them to the current Work
  # Arguments:
  #  * array of tag strings
  def tag_strings=(tag_strings)
    #default to empty array of keywords
    tag_strings ||= []  
          
    #Initialize keywords
    tags = Array.new
    tag_strings.to_a.uniq.each do |add|
      tags << Tag.find_or_initialize_by_name(add)
    end
    
    #save or update Work
    self.tags = tags   
  end 

  # Updates keywords for the current Work
  # If this Work is still a *new* record (i.e. it hasn't been created
  # in the database), then the keywords are just cached until the 
  # Work is created.
  # Based on ideas at:
  #   http://blog.hasmanythrough.com/2007/1/22/using-faux-accessors-to-initialize-values
  #
  # Arguments:
  #  * array of Keywords
  def keywords=(keywords)
    logger.debug("\n\n===SET KEYWORDS===\n\n")
    logger.debug("Keywords= #{keywords.inspect}")
    if self.new_record?
      #Defer saving keywords to Work object directly, until it is created
      @keywords_cache = keywords
    else
      # Create keywords and save to database
      Work.update_keywordings(self, keywords)  
    end
  end  
  
  # Updates tags for the current Work
  # If this Work is still a *new* record (i.e. it hasn't been created
  # in the database), then the tags are just cached until the 
  # Work is created.
  # Based on ideas at:
  #   http://blog.hasmanythrough.com/2007/1/22/using-faux-accessors-to-initialize-values
  #
  # Arguments:
  #  * array of Tags
  def tags=(tags)
    logger.debug("\n\n===SET TAGS===\n\n")
    logger.debug("Tags= #{tags.inspect}")
    if self.new_record?
      #Defer saving to Work object directly, until it is created
      @tags_cache = tags
    else
      # Create keywords and save to database
      Work.update_taggings(self, tags)  
    end
  end  
  
  # Updates Work name strings
  # (from a hash of "name" and "role" values)
  # and saves them to the current Work
  # Arguments:
  #  * hash {:name => "Donohue, T.", :role => "Author | Editor" }
  def work_name_strings=(work_name_string_hash)
    logger.debug("\n\n===SET WORK_NAME_STRINGS===\n\n")
    logger.debug("WorkNameStrings: #{work_name_string_hash.inspect}")
    
    
    if self.new_record?
      #Defer saving to Work object directly, until it is created
      @work_name_strings_cache = work_name_string_hash
    else
      # Create name_strings and save to database
      Work.update_work_name_strings(self, work_name_string_hash)  
    end
    
  end 
 
  # Initializes the Publication information
  # and saves it to the current Work
  # Arguments:
  #  * hash {:name => "Publication name", 
  #          :issn_isbn => "Publication ISSN or ISBN",
  #          :publisher_name => "Publisher name" }
  #  (not all hash values need be set)
  def publication_info=(publication_hash)
    logger.debug("\n\n===SET PUBLICATION INFO===\n\n")

    # Unknown publication names should be set to Unknown
    # already. Nil is accepted for some work types.
    publication_name = publication_hash[:publication_name]
    
    
    # If there is no publisher name, set to Unknown
    publisher_name = publication_hash[:publisher_name]
    if publisher_name.nil? || publisher_name.empty?
      publisher_name = "Unknown"
    end
    #Create and assign publisher
    publisher = Publisher.find_or_create_by_name(publisher_name)
    self.publisher = publisher
    self.authority_publisher_id = publisher.authority.id

    if publication_name
      # We can have more than one Publisher name
      # Ex: [Physics of Plasmas, Phys Plasmas]
      publication_name.each do |pub_name|
        # Initialize our publication, as best we can,
        # based on the information provided

        # English: If you have an issn or isbn and good publisher data
        if not(publication_hash[:issn_isbn].nil? || publication_hash[:issn_isbn].empty?)
          publication = Publication.find_or_create_by_name_and_issn_isbn_and_publisher_id(
              :name => pub_name,
              :issn_isbn => publication_hash[:issn_isbn],
              :publisher_id => publisher.authority_id
          )
        elsif not(publisher.nil?)
          publication = Publication.find_or_create_by_name_and_publisher_id(
              :name => pub_name,
              :publisher_id => publisher.authority_id
          )
        else
          publication = Publication.find_or_create_by_name(pub_name)
        end

        #save or update Work
        self.publication = publication
        self.authority_publication_id = publication.authority.id
      end
    end
  end
 
  # All Works begin unverified
  def set_initial_states
    self.is_in_process
    self.init_archive_status
  end

  #Build a unique ID for this Work in Solr
  def solr_id
    "Work-#{id}"
  end

  # Generate a key based on title information
  # which can be used to determine if a Work is a duplicate
  def title_dupe_key
    # Title Dupe Key Format:
    # [Work.machine_name]||[Work.year]||[Publication.machine_name]
    unless self.publication.nil? or self.publication.authority.nil?
      self.machine_name.to_s + "||" + self.year.to_s + "||" + self.publication.authority.machine_name.to_s
    end
  end
  
  # Generate a key based on Author/Editor information
  # which can be used to determine if a Work is a duplicate
  def name_string_dupe_key
    # NameString Dupe Key Format:
    # [First NameString.machine_name]||[Work.year]||[Work.type]||[Work.machine_name]
    unless self.name_strings.nil? or self.name_strings.empty?
      self.name_strings[0].machine_name.to_s + "||" + self.year.to_s + "||" + self.type.to_s + "||" + self.machine_name.to_s
    end
  end
  
  
  def create_contributorships
    logger.debug "\n\n===== CREATE CONTRIBUTORSHIPS =====\n\n"
    # After save method
    # Ensures Contributorships are set for each WorkNameString claim
    # associated with the Work.
    logger.debug "Work State: #{self.work_state_id}\n"
    logger.debug "CNS Size: #{self.work_name_strings.size}"
    
    # Only create contributorships for accepted Works...
    if self.accepted?
      self.work_name_strings.each do |cns|
        # Find all People with a matching PenName claim
        claims = PenName.find(:all, :conditions => ["name_string_id = ?", cns.name_string_id])
        
        # Debugger
        logger.debug("\n Claims: ")
        claims.each do |c| 
          logger.debug("#{c.person.display_name}")
        end
        
        # Find or create a Contributorship for each claim
        claims.each do |claim|
          contributorship=Contributorship.find_or_create_by_work_id_and_person_id_and_pen_name_id_and_role(
            self.id,
            claim.person.id, 
            claim.id,
            cns.role
          )
        end
      end
    end
  end

  def update_scoring_hash
    logger.debug "\n\n===== UPDATE SCORING HASH ===== \n\n"
    if self.publication_date != nil
      year = self.publication_date.year
    else
      year = nil
    end
    
    publication_id = self.publication_id
    collaborator_ids = self.name_strings.collect{|ns| ns.id}
    keyword_ids = self.keywords.collect{|k| k.id}
    
    # Return a hash comprising all the Contributorship scoring methods
    scoring_hash = {
      :year => year, 
      :publication_id => publication_id,
      :collaborator_ids => collaborator_ids,
      :keyword_ids => keyword_ids
    }
    self.scoring_hash = scoring_hash
    self.save_without_callbacks
  end
  
  #Update archive status of Work
  def update_archive_state  
    #if archived date set, its in archived state! 
    if !self.archived_at.nil? 
      #this Work is officially "archived"!
      self.is_archived
      self.save_without_callbacks
    #check if Work has attachments
    elsif !self.attachments.nil? and !self.attachments.empty?
      #if attachments exist, change status to "ready to archive"
      if !self.ready_to_archive?
        self.is_ready_to_archive
        self.save_without_callbacks
      end
    elsif self.ready_to_archive? 
      #else if marked ready, but no attachments
      #then, revert to initial status  
      self.init_archive_status
      self.save_without_callbacks
    end
  end
  
  #Update Machine Name of Work (called by after_save callback)
  def update_machine_name
    #Machine name only needs updating if title primary changes or empty
    if self.title_primary_changed? or self.machine_name.nil?
      #Machine name is Title Primary with:
      #  1. all punctuation/spaces converted to single space
      #  2. stripped of leading/trailing spaces and downcased
      self.machine_name = self.title_primary.mb_chars.gsub(/[\W]+/, " ").strip.downcase
      self.save_without_callbacks
    end
  end
  
  #Update Publication and Publisher Authorities (called by after_save callback)
  def update_authorities
    if !self.publication.nil?
      self.authority_publication_id  = self.publication.authority.id
      self.authority_publisher_id    = self.publication.authority.publisher.id
      self.save_without_callbacks
    end
  end
  
  # Returns to Work Type URI based on the EPrints Application Profile's
  # Type vocabulary.  If the type is not available in the EPrints App Profile,
  # then the URI of the appropriate DCMI Type is returned.
  #
  # This is used for generating a SWORD package
  # which contains a METS file conforming to the EPrints DC XML Schema. 
  #
  # For more info on EPrints App. Profile, and it's Type vocabulary, see:
  # http://www.ukoln.ac.uk/repositories/digirep/index/EPrints_Application_Profile
  def type_uri
    
    #Maps our Work Types to EPrints Application Profile Type URIs,
    # or to the DCMI Type Vocabulary URI (if not in EPrints App. Profile)
    # @TODO - Is there a better place to store this mapping info?  DB maybe? 
    #         Should each Work subclass just define its own "type_uri"?
    type_map = {
      "Abstract"    => "http://purl.org/eprint/type/ScholarlyText",
      "Artwork"     => "http://purl.org/dc/dcmitype/Image",  #DCMI Type
      #"BillResolutions" => ??
      "BookEdited"  => "http://purl.org/eprint/type/Book",
      "BookReview"  => "http://purl.org/eprint/type/BookReview",
      "BookSection" => "http://purl.org/eprint/type/BookItem",
      "BookWhole"   => "http://purl.org/eprint/type/Book",
      "ComputerProgram" => "http://purl.org/dc/dcmitype/Software", #DCMI Type
      "ConferencePaper" =>  " http://purl.org/eprint/type/ConferencePaper",
      "ConferencePoster" => "http ://purl.org/eprint/type/ConferencePoster",
      "ConferenceProceeding" => "http://purl.org/eprint/type/ConferenceItem",
      #"CourtCaseDecision" => ??
      "DissertationThesis" => "http://purl.org/eprint/type/Thesis",
      "Generic" => "http://purl.org/eprint/type/ScholarlyText",
      "Grant" => "http://purl.org/eprint/type/ScholarlyText",
      #"Hearing" => ??
      "JournalArticle" => "http://purl.org/eprint/type/JournalArticle",
      #"LawStatutes" => ??
      "MagazineArticle" => "http://purl.org/eprint/type/JournalArticle",
      "Map" => "http://purl.org/dc/dcmitype/StillImage", #DCMI Type
      "Monograph" => "http://purl.org/eprint/type/Book",
      "MotionPicture" => "http://purl.org/dc/dcmitype/MovingImage", #DCMI Type
      "MusicScore" => "http://purl.org/dc/dcmitype/Text",
      "NewspaperArticle" => "http://purl.org/eprint/type/NewsItem",
      "Patent" => "http://purl.org/eprint/type/Patent",
      #"PersonalCommunication" => ??
      "Report" => "http://purl.org/eprint/type/Report",
      "SoundRecording" => "http://purl.org/dc/dcmitype/Sound", #DCMI Type
      "UnpublishedMaterial" => "http://purl.org/eprint/type/ScholarlyText",
      "Video" => "http://purl.org/dc/dcmitype/MovingImage", #DCMI Type
      "WebPage" => "http://purl.org/dc/dcmitype/InteractiveResource", #DCMI Type
    }
    
    type_map[self.type]
  end
  
  #Convert Work into a String
  def to_s
    # Default to displaying Work in APA citation format
    to_apa
  end
  
  #Convert Work into a String in the APA Citation Format
  # This is currently used during generation of METS file
  # conforming to EPrints DC XML Schema for use with SWORD.
  # @TODO: There is likely a better way to do this more generically.
  def to_apa
    citation_string = ""
    
    #---------------------------------------------
    # All APA Citation formats start out the same:
    #---------------------------------------------
    #Add authors
    self.name_strings.author.each do |ns|
      if citation_string == ""
        citation_string << ns.name
      else
        citation_string << ", #{ns.name}"
      end 
    end
    
    #Add editors
    self.name_strings.editor.each do |ns|
      if citation_string == ""
        citation_string << ns.name
      else
        citation_string << ", #{ns.name}"
      end 
    end
    citation_string << " (Ed.)." if self.name_strings.editor.size == 1
    citation_string << " (Eds.)." if self.name_strings.editor.size > 1
    
    #Publication year
    citation_string << " (#{self.publication_date.year})" if self.publication_date
    
    #Only add a period if the string doesn't currently end in a period.
    citation_string << ". " if !citation_string.match("\.\s*\Z")
    
    #Title
    citation_string << "#{self.title_primary}. " if self.title_primary
    
    #---------------------------------------
    #Formatting specific to type of Work
    #---------------------------------------
    case self.class
    when BookWhole
   
      citation_string << self.publisher.authority.name if self.publisher
      #Only add a period if the string doesn't currently end in a period.
      citation_string << ". " if !citation_string.match("\.\s*\Z")
    
    when ConferencePaper #Conference Proceeding in APA Format
      
      citation_string << "In #{self.title_secondary}" if self.title.secondary
      citation_string << ": Vol. #{self.volume}" if self.volume
      #Only add a period if the string doesn't currently end in a period.
      citation_string << ". " if !citation_string.match("\.\s*\Z")
      citation_string << "#{self.publication.authority.name}" if self.publication
      citation_string << ", (" if self.start_page or self.end_page
      citation_string << self.start_page if self.start_page
      citation_string << "-#{self.end_page}" if self.end_page
      citation_string << ")" if self.start_page or self.end_page
      citation_string << "." if !citation_string.match("\.\s*\Z")
      citation_string << self.publisher.authority.name if self.publisher
      citation_string << "."

    else #default to JournalArticle in APA format
      
      citation_string << "#{self.publication.authority.name}, " if self.publication
      citation_string << self.volume if self.volume
      citation_string << "(#{self.issue})" if self.issue
      citation_string << ", " if self.start_page or self.end_page
      citation_string << self.start_page if self.start_page
      citation_string << "-#{self.end_page}" if self.end_page
      citation_string << "."
    
    end
    
    
    citation_string
  end

  #Get all Author names on a Work, return as an array of hashes
  def authors
    authors = Array.new
    names = self.name_strings.find(:all, :conditions => [ 'role=?', 'Author']).collect{|ns| {:name => ns.name, :id => ns.id}}
    names.each do |name|
      authors << {:name => name[:name], :id => name[:id]}
    end
    return authors
  end

   #Get all Editor Strings of a Work, return as an array of hashes
  def editors
    editors = Array.new
    names = self.name_strings.find(:all, :conditions => [ 'role=?', 'Editor']).collect{|ns| {:name => ns.name, :id => ns.id}}
    names.each do |name|
      editors << {:name => name[:name], :id => name[:id]}
    end
    return editors
  end
  
  def publication_authority
    Publication.find(:first, :conditions => ["id = ?", self.authority_publication_id])
  end
  
  def publisher_authority
    Publisher.find(:first, :conditions => ["id = ?", self.authority_publisher_id])
  end
 
  # In case there isn't a subklass open_url_kevs method
  def open_url_kevs
    open_url_kevs = Hash.new
    open_url_kevs[:format]     = "&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal"
    open_url_kevs[:genre]      = "&rft.genre=article"
    open_url_kevs[:title]      = "&rft.atitle=#{CGI.escape(self.title_primary)}"
    unless self.publication.nil?
      open_url_kevs[:source]     = "&rft.jtitle=#{self.publication.authority.name}"
      open_url_kevs[:issn]       = "&rft.issn=#{self.publication.issns.first[:name]}" if !self.publication.issns.empty?
    end
    open_url_kevs[:date]       = "&rft.date=#{self.publication_date}"
    open_url_kevs[:volume]     = "&rft.volume=#{self.volume}"
    open_url_kevs[:issue]      = "&rft.issue=#{self.issue}"
    open_url_kevs[:start_page] = "&rft.spage=#{self.start_page}"
    open_url_kevs[:end_page]   = "&rft.epage=#{self.end_page}"
    
    return open_url_kevs
  end

  def update_type_and_save_without_callbacks(new_type)
    self[:type] = new_type
    self.save_without_callbacks
  end
 
  ### PRIVATE METHODS ###
  private
  
  # Update Keywordings - updates list of keywords for Work
  # Arguments:
  #   - Work object
  #   - collection of Keyword objects
  def self.update_keywordings(work, keywords)
    logger.debug("\n\n===UPDATE KEYWORDINGS===\n\n")
    
    unless keywords.nil?
      #first, remove any keyword(s) that are no longer in list
      work.keywordings.each do |kw|
        kw.destroy unless keywords.include?(kw.keyword)
        keywords.delete(kw.keyword)
      end
      #next, add any new keyword(s) to list
      keywords.each do |keyword|
        #if this is a brand new keyword, we must save it first
        if keyword.new_record?
          keyword.save
        end
        #add it to this Work
        work.keywords << keyword
      end
      
    end #end unless no keywords

    logger.debug("Work Keywords Saved= #{work.keywords.inspect}")
  end   
  
  def self.update_taggings(work, tags)
    logger.debug("\n\n===UPDATE TAGS===\n\n")
    
    unless tags.nil?
      #first, remove any tag(s) that are no longer in list
      work.taggings.each do |kw|
        kw.destroy unless tags.include?(kw.tag)
        tags.delete(kw.tag)
      end
      #next, add any new tag(s) to list
      tags.each do |tag|
        #if this is a brand new tag, we must save it first
        if tag.new_record?
          tag.save
        end
        #add it to this Work
        work.tags << tag
        
      end
      
    end #end unless no tags

    logger.debug("Work Tags Saved= #{work.tags.inspect}")
  end   
  
  # Create keywords, after a Work is created successfully
  #  Called by 'after_create' callback
  def create_keywords
    logger.debug("===CREATE KEYWORDS===") 
    logger.debug("Cached Keywords= #{@keywords_cache.inspect}")
    #Create any initialized keywords and save to Work
    self.keywords = @keywords_cache if @keywords_cache
  end
 
 
  def create_tags
    logger.debug("===CREATE TAGS===") 
    logger.debug("Cached Tags= #{@tags_cache.inspect}")
    #Create any initialized tags and save to Work
    self.tags = @tags_cache if @tags_cache
  end 

  # Updates WorkNameStrings
  # (from a hash of "name" and "role" values)
  # and saves them to the given Work object
  # Arguments:
  #  * Work object
  #  * Array of hashes {:name => "Donohue, Tim", :role=> "Author | Editor" }
  def self.update_work_name_strings(work, name_strings_hash)
    logger.debug("\n\n===UPDATE WORK_NAME_STRINGS===\n\n")
    unless name_strings_hash.nil?
      #First, remove *ALL* existing name_string(s).  We want to add them
      #all again from scratch, since the order of Authors/Editors *matters*
      work.work_name_strings.each do |cns| # Current CNSs
        cns.destroy
      end
        
      #next, re-add all name string(s) to list
      name_strings_hash.flatten.each do |cns|
        #Generate the "machine_name" for this namestring...this is our unique name with punctuation removed, etc.
        machine_name = cns[:name].gsub(".", " ").gsub(",", " ").gsub(/ +/, " ").strip.downcase
        name_string = NameString.find_or_create_by_machine_name(machine_name)
        
        #add it to this Work
        WorkNameString.create(
          :work_id => work.id,
          :name_string_id => name_string.id, 
          :role => cns[:role]
        )
      end
    end
  end    
  
  # Create WorkNameStrings, after a Work is created successfully
  #  Called by 'after_create' callback
  def create_work_name_strings
    logger.debug("===CREATE WORK_NAME_STRINGS===")    
    logger.debug("Cached CNS= #{@work_name_strings_cache.inspect}")
    
    #Create any initialized name_strings and save to Work
    self.work_name_strings = @work_name_strings_cache if @work_name_strings_cache
  end
  
end
