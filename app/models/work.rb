class Work < ActiveRecord::Base
  
  acts_as_authorizable  #some actions on Works require authorization
  

  cattr_accessor :current_user
  
  serialize :scoring_hash
  
  #### Associations ####
  belongs_to :publication
  belongs_to :publisher
  
  has_many :name_strings, :through => :work_name_strings,
    :order => "position"
  
  has_many :work_name_strings,
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

  def after_create 
   	create_work_name_strings
  	create_keywords
    create_tags
    #save any changes to work
    self.save_without_callbacks
    
   
  end
  
  def after_save
    logger.debug("\n\n === After Save ===\n\n")

    # The Work object needs to be reloaded into memory,
    # otherwise the faux-accessors will *not* be available in the
    # after_save callbacks.
    self.reload
    deduplicate
    
    self.reload
    create_contributorships
    
    self.reload
    update_scoring_hash
    
    update_archive_state
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
		  "Add Batch",
      "Book (Edited)",
      "Book (Section)",
      "Book (Whole)",
      "Conference Proceeding",
		  "Journal Article", 
      "Report",
      "Generic"
	  ]  
  end
  
  
  # Deduplication: deduplicate Work records on create
  def deduplicate
    logger.debug("\n\n===DEDUPLICATE===\n\n")

    dupe_candidates = duplicates
    logger.debug("\nDuplicates: #{duplicates.size}")

    if dupe_candidates.empty?
      self.is_accepted
      self.save_without_callbacks
      return
    end
    
    if dupe_candidates.size < 2
      self.is_accepted
      self.save_without_callbacks
      return
    end
    
    best = dupe_candidates[0]
    dupe_candidates.each do |candidate|
      if candidate.preferred_score > best.preferred_score
        best = candidate
      end
    end

    unless best.duplicate?
      # Flag and save this as the canonical beast.
      best.is_accepted
      best.save_without_callbacks
    end

    # All the others are, by definition, dupes
    dupe_candidates.each do |dupe|
      logger.debug "Saving dupe work_states: #{dupe.id}"
      if dupe.accepted?
        # Do nothing
      else
        dupe.is_duplicate
        dupe.batch_index = 0
        dupe.save_without_callbacks
      end
    end
  end

  # Deduplication: search for Work duplicates
  def duplicates
    # This is Very Slow (at least on mysql) when done in one query with an OR:
    # mysql will only use one index per query, and the or implies that your index 
    # would need to be indexed with more than one key first.
    # Alternative approach: use find_by_sql and UNION
    issn_dupes = Work.find(:all, 
      :conditions => ["work_state_id <> 2 and issn_isbn_dupe_key = ?", self.issn_isbn_dupe_key])
    title_dupes = Work.find(:all, 
      :conditions => ["work_state_id <> 2 and title_dupe_key = ?", self.title_dupe_key])
    return (issn_dupes + title_dupes).uniq
  end
  
  def year
    if publication_date != nil
      publication_date.year
    else
      nil
    end
  end
  
  # Deduplication: set score
  def preferred_score
    # The highest score will win... currently, we like things from Engineering Village folders,
    # and really like things that are already accepted.
    score = 0
    #score = 1 if (folder["- ev"])
    score = 10 if self.accepted?
    score
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
		  #Defer saving to Work object directly, until it is created
		  @keywords_cache = keywords
    else
		  # Create keywords and save to database
		  Work.update_keywordings(self, keywords)  
		end
  end  
  
  
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
    # If there is no publication name, set to Unknown
    publication_name = publication_hash[:name]
    if publication_name.nil? || publication_name.empty?
      publication_name = "Unknown"
    end
    
    # If there is no publisher name, set to Unknown
    publisher_name = publication_hash[:publisher_name]
    if publisher_name.nil? || publisher_name.empty?
      publisher_name = "Unknown"
    end
    #Create and assign publisher
    publisher = Publisher.find_or_create_by_name(publisher_name)
    self.publisher = publisher.authority
   
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
      self.publication = publication.authority
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

  def self.set_issn_isbn_dupe_key(work, work_name_strings, issn_isbn)
    # Set issn_isbn_dupe_key
    if !work_name_strings.nil? 
      if work_name_strings[0] != nil
        logger.debug("\nCNS: #{work_name_strings.inspect}\n")
        first_author = work_name_strings[0][:name].split(",")[0]
      else
        first_author = nil
      end
    else
      first_author = nil
    end
        
    if (first_author.nil? or issn_isbn.nil? or work.publication_date.nil? or work.start_page.nil? or work.start_page.empty? or issn_isbn.empty?)
      issn_isbn_dupe_key = nil
    else
      issn_isbn_dupe_key = (first_author+issn_isbn+work.publication_date.year.to_s+work.start_page.to_s).gsub(/[^0-9A-Za-z]/, '').downcase
    end
  end
    
  def self.set_title_dupe_key(work)
    # Set title_dupe_key      
    if work.title_primary.nil? or work.publication_date.nil? or work[:type].nil? or work.start_page.nil?
      title_dupe_key = nil
    else 
      title_dupe_key = work.title_primary.downcase.gsub(/[^a-z]/,'').first(200)+work.publication_date.year.to_s+work[:type].to_s+work.start_page.to_s
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
          logger.debug("#{c.person.name}")
        end
    
        # Find or create a Contributorship for each claim
        # @TODO: Incorporate a Person.blacklist?
        claims.each do |claim|
          Contributorship.find_or_create_by_work_id_and_person_id_and_pen_name_id_and_role(
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
    when BookWhole, BookEdited
   
      citation_string << self.publisher.authority.name if self.publisher
      #Only add a period if the string doesn't currently end in a period.
      citation_string << ". " if !citation_string.match("\.\s*\Z")
    
    when ConferenceProceeding #Conference Proceeding in APA Format
      
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

  
  ##### CSL Simple Citation Variables #####

  #Get all Author names on a Work, return as an array of hashes
  def authors
    authors = Array.new
    names = self.name_strings.find(:all, :conditions => [ 'role=?', 'Author']).collect{|ns| ns.name}
    names.each do |name|
      authors << {:name => name}
    end
    return authors
  end
  
   #Get all Editor Strings of a Work, return as an array of hashes
  def editors
    editors = Array.new
    names = self.name_strings.find(:all, :conditions => [ 'role=?', 'Editor']).collect{|ns| ns.name}
    names.each do |name|
      editors << {:name => name}
    end
    return editors
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
