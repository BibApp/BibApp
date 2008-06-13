class Citation < ActiveRecord::Base
  
  acts_as_authorizable  #some actions on citations require authorization
  
  serialize :scoring_hash
  
  #### Associations ####
  belongs_to :publication
  belongs_to :publisher
  
  has_many :name_strings, :through => :citation_name_strings do 

    # @TODO: Rails 2.1 named scope these methods
    def authors
      find(:all, :conditions => ["role = ?", "Author"], :order => :position)
    end
    
    def editors
      find(:all, :conditions => ["role = ?", "Editor"], :order => :position)      
    end
  end 
  
  has_many :citation_name_strings,
    :dependent => :delete_all
  
  has_many :people,
    :through => :contributorships,
    :conditions => ["contributorship_state_id = ?", 2]
    
  has_many :contributorships,
    :dependent => :delete_all
  
  has_many :keywords, :through => :keywordings
  has_many :keywordings,
    :dependent => :delete_all
  
  has_many :external_system_uris
  
  has_many :attachments, :as => :asset
  belongs_to :citation_archive_state 

  #### Callbacks ####
  before_validation_on_create :set_initial_states

  def after_create 
   	create_citation_name_strings
  	create_keywords
    #save any changes to citation
    self.save_without_callbacks
  end
  
  def after_save
    logger.debug("\n\n === After Save ===\n\n")

    # The Citation object needs to be reloaded into memory,
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

  ########## Methods ##########
  # Rule #1: Comment H-E-A-V-I-L-Y
  # Rule #2: Include @TODOs
  
  # List of all currently enabled Citation Types
  def self.types
  	# @TODO: Add each citation subklass to this array
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
  
  
  # Deduplication: deduplicate Citation records on create
  def deduplicate
    logger.debug("\n\n===DEDUPLICATE===\n\n")

    dupe_candidates = duplicates
    logger.debug("\nDuplicates: #{duplicates.size}")

    if dupe_candidates.empty?
      self.citation_state_id = 3
      self.save_without_callbacks
      return
    end
    
    if dupe_candidates.size < 2
      self.citation_state_id = 3
      self.save_without_callbacks
      return
    end
    
    best = dupe_candidates[0]
    dupe_candidates.each do |candidate|
      if candidate.preferred_score > best.preferred_score
        best = candidate
      end
    end

    unless best.citation_state_id == 2
      # Flag and save this as the canonical beast.
      best.citation_state_id = 3
      best.save_without_callbacks
    end

    # All the others are, by definition, dupes
    dupe_candidates.each do |dupe|
      logger.debug "Saving dupe citation_states: #{dupe.id}"
      if dupe.citation_state_id == 3
        # Do nothing
      else
        dupe.citation_state_id = 2
        dupe.batch_index = 0
        dupe.save_without_callbacks
      end
    end
  end

  # Deduplication: search for Citation duplicates
  def duplicates
    # This is Very Slow (at least on mysql) when done in one query with an OR:
    # mysql will only use one index per query, and the or implies that your index 
    # would need to be indexed with more than one key first.
    # Alternative approach: use find_by_sql and UNION
    issn_dupes = Citation.find(:all, 
      :conditions => ["citation_state_id <> 2 and issn_isbn_dupe_key = ?", self.issn_isbn_dupe_key])
    title_dupes = Citation.find(:all, 
      :conditions => ["citation_state_id <> 2 and title_dupe_key = ?", self.title_dupe_key])
    return (issn_dupes + title_dupes).uniq
  end
  
  def year
    publication_date.year
  end
  
  # Deduplication: set score
  def preferred_score
    # The highest score will win... currently, we like things from Engineering Village folders,
    # and really like things that are already accepted.
    score = 0
    #score = 1 if (folder["- ev"])
    score = 10 if citation_state_id == 3
    score
  end
  
  def save_without_callbacks
    create_or_update_without_callbacks
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
  # and saves them to the current citation
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
    
    #save or update citation
    self.keywords = keywords   
  end 

  # Updates keywords for the current citation
  # If this citation is still a *new* record (i.e. it hasn't been created
  # in the database), then the keywords are just cached until the 
  # citation is created.
  # Based on ideas at:
  #   http://blog.hasmanythrough.com/2007/1/22/using-faux-accessors-to-initialize-values
  #
  # Arguments:
  #  * array of Keywords
  def keywords=(keywords)
    logger.debug("\n\n===SET KEYWORDS===\n\n")
    logger.debug("Keywords= #{keywords.inspect}")
    if self.new_record?
		  #Defer saving to Citation object directly, until it is created
		  @keywords_cache = keywords
    else
		  # Create keywords and save to database
		  Citation.update_keywordings(self, keywords)  
		end
  end  
  
  
  # Updates citation name strings
  # (from a hash of "name" and "role" values)
  # and saves them to the current citation
  # Arguments:
  #  * hash {:name => "Donohue, T.", :role => "Author | Editor" }
  def citation_name_strings=(citation_name_string_hash)
    logger.debug("\n\n===SET CITATION_NAME_STRINGS===\n\n")
    logger.debug("CitationNameStrings: #{citation_name_string_hash.inspect}")
    
    
    if self.new_record?
      #Defer saving to Citation object directly, until it is created
      @citation_name_strings_cache = citation_name_string_hash
    else
      # Create name_strings and save to database
      Citation.update_citation_name_strings(self, citation_name_string_hash)  
    end
    
  end 
  
  # Initializes the Publication information
  # and saves it to the current citation
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
    
    publication_name.each do |publication_name|
      # Initialize our publication, as best we can,
      # based on the information provided

      # English: If you have an issn or isbn and good publisher data 
      if not(publication_hash[:issn_isbn].nil? || publication_hash[:issn_isbn].empty?)
        publication = Publication.find_or_create_by_name_and_issn_isbn_and_publisher_id(
            :name => publication_name, 
            :issn_isbn => publication_hash[:issn_isbn], 
            :publisher_id => publisher.authority_id
        )
      elsif not(publisher.nil?)
        publication = Publication.find_or_create_by_name_and_publisher_id(
            :name => publication_name,  
            :publisher_id => publisher.authority_id
        )
      else
        publication = Publication.find_or_create_by_name(publication_name)
      end

      #save or update citation
      self.publication = publication.authority
    end
  end
 
  # All Citations begin unverified
  def set_initial_states
    self.citation_state_id = 1
    self.citation_archive_state = CitationArchiveState.initial
  end

  def solr_id
    "Citation-#{id}"
  end

  def self.set_issn_isbn_dupe_key(citation, citation_name_strings, issn_isbn)
    # Set issn_isbn_dupe_key
    logger.debug("\nCNS: #{citation_name_strings.inspect}\n")
    if citation_name_strings[0] != nil 
      first_author = citation_name_strings[0][:name].split(",")[0]
    else
      first_author = nil
    end
        
    if (first_author.nil? or issn_isbn.nil? or citation.publication_date.nil? or citation.start_page.nil? or citation.start_page.empty? or issn_isbn.empty?)
      issn_isbn_dupe_key = nil
    else
      issn_isbn_dupe_key = (first_author+issn_isbn+citation.publication_date.year.to_s+citation.start_page.to_s).gsub(/[^0-9A-Za-z]/, '').downcase
    end
  end
    
  def self.set_title_dupe_key(citation)
    # Set title_dupe_key      
    if citation.title_primary.nil? or citation.publication_date.nil? or citation[:type].nil? or citation.start_page.nil?
      title_dupe_key = nil
    else 
      title_dupe_key = citation.title_primary.downcase.gsub(/[^a-z]/,'').first(200)+citation.publication_date.year.to_s+citation[:type].to_s+citation.start_page.to_s
    end
  end
 
  #Get all Author Strings of a citation, return as NameString objects
  def author_name_strings
    self.name_strings.find(:all, :conditions => [ 'role=?', 'Author'])
  end 
  
   #Get all Editor Strings of a citation, return as NameString objects
  def editor_name_strings
    self.name_strings.find(:all, :conditions => [ 'role=?', 'Editor'])
  end
  
  def create_contributorships
    logger.debug "\n\n===== CREATE CONTRIBUTORSHIPS =====\n\n"
    # After save method
    # Ensures Contributorships are set for each CitationNameString claim
    # associated with the Citation.
    logger.debug "Citation State: #{self.citation_state_id}\n"
    logger.debug "CNS Size: #{self.citation_name_strings.size}"
    
    # Only create contributorships for accepted citations...
    if self.citation_state_id == 3
      self.citation_name_strings.each do |cns|
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
          Contributorship.find_or_create_by_citation_id_and_person_id_and_pen_name_id_and_role(
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
  
  #Update archive status of Citation
  def update_archive_state  
    #if archived date set, its in archived state! 
    if !self.archived_at.nil? 
      #this citation is officially "archived"!
      self.citation_archive_state = CitationArchiveState.archived
      self.save_without_callbacks
    #check if citation has attachments
    elsif !self.attachments.nil? and !self.attachments.empty?
      #if attachments exist, change status to "ready to archive"
      if !CitationArchiveState.ready_to_archive?(self)
        self.citation_archive_state = CitationArchiveState.ready_to_archive
        self.save_without_callbacks
      end
    elsif CitationArchiveState.ready_to_archive?(self) 
      #else if marked ready, but no attachments
      #then, revert to initial status  
      self.citation_archive_state = CitationArchiveState.initial
      self.save_without_callbacks
    end
  end
  
  # Returns to citation Type URI based on the EPrints Application Profile's
  # Type vocabulary.  If the type is not available in the EPrints App Profile,
  # then the URI of the appropriate DCMI Type is returned.
  #
  # This is used for generating a SWORD package
  # which contains a METS file conforming to the EPrints DC XML Schema. 
  #
  # For more info on EPrints App. Profile, and it's Type vocabulary, see:
  # http://www.ukoln.ac.uk/repositories/digirep/index/EPrints_Application_Profile
  def type_uri
    
    #Maps our Citation Types to EPrints Application Profile Type URIs,
    # or to the DCMI Type Vocabulary URI (if not in EPrints App. Profile)
    # @TODO - Is there a better place to store this mapping info?  DB maybe? 
    #         Should each citation subclass just define its own "type_uri"?
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
  
  #Convert citation into a String
  def to_s
    # Default to displaying citation in APA citation format
    to_apa
  end
  
  #Convert citation into a String in the APA Citation Format
  # This is currently used during generation of METS file
  # conforming to EPrints DC XML Schema for use with SWORD.
  # @TODO: There is likely a better way to do this more generically.
  def to_apa
    citation_string = ""
    
    #---------------------------------------------
    # All APA Citation formats start out the same:
    #---------------------------------------------
    #Add authors
    self.author_name_strings.each do |ns|
      if citation_string == ""
        citation_string << ns.name
      else
        citation_string << ", #{ns.name}"
      end 
    end
    
    #Add editors
    self.editor_name_strings.each do |ns|
      if citation_string == ""
        citation_string << ns.name
      else
        citation_string << ", #{ns.name}"
      end 
    end
    citation_string << " (Ed.)." if self.editor_name_strings.size == 1
    citation_string << " (Eds.)." if self.editor_name_strings.size > 1
    
    #Publication year
    citation_string << " (#{self.publication_date.year})" if self.publication_date
    
    #Only add a period if the string doesn't currently end in a period.
    citation_string << ". " if !citation_string.match("\.\s*\Z")
    
    #Title
    citation_string << "#{self.title_primary}. " if self.title_primary
    
    #---------------------------------------
    #Formatting specific to type of Citation
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
  
  ### PRIVATE METHODS ###
  private
  
  # Update Keywordings - updates list of keywords for citation
  # Arguments:
  #   - citation object
  #   - collection of Keyword objects
  def self.update_keywordings(citation, keywords)
    logger.debug("\n\n===UPDATE KEYWORDINGS===\n\n")
    
    unless keywords.nil?
      #first, remove any keyword(s) that are no longer in list
      citation.keywordings.each do |kw|
        kw.destroy unless keywords.include?(kw.keyword)
        keywords.delete(kw.keyword)
      end
      #next, add any new keyword(s) to list
      keywords.each do |keyword|
        #if this is a brand new keyword, we must save it first
        if keyword.new_record?
          keyword.save
        end
        #add it to this citation
        citation.keywords << keyword
      end
      
    end #end unless no keywords

    logger.debug("Citation Keywords Saved= #{citation.keywords.inspect}")
  end   
  
  # Create keywords, after a Citation is created successfully
  #  Called by 'after_create' callback
  def create_keywords
    logger.debug("===CREATE KEYWORDS===") 
    logger.debug("Cached Keywords= #{@keywords_cache.inspect}")
    #Create any initialized keywords and save to Citation
    self.keywords = @keywords_cache if @keywords_cache
  end  
 
  
  # Updates citation name strings
  # (from a hash of "name" and "role" values)
  # and saves them to the given citation object
  # Arguments:
  #  * citation object
  #  * hash {:name => "Donohue, t>", :role=> "Author | Editor" }
  def self.update_citation_name_strings(citation, name_strings_hash)
    logger.debug("\n\n===UPDATE CITATION_NAME_STRINGS===\n\n")
    unless name_strings_hash.nil?
      #first, remove any name_string(s) that are no longer in list
      citation.citation_name_strings.each do |cns| # Current CNSs
        cns.destroy unless name_strings_hash.collect{|c| c[:name]}.include?(cns.name_string.name)
      end
       
      #next, add any new name string(s) to list
      name_strings_hash.flatten.each do |cns|
        #if this is a brand new name_string, we must save it first
        logger.debug("CNS: #{cns.inspect}")
        name_string = NameString.find_or_create_by_name(cns[:name])
        
        #add it to this citation
        CitationNameString.create(
                                  :citation_id => citation.id,
                                  :name_string_id => name_string.id, 
                                  :role => cns[:role]
                               )
      end
    end
  end    
  
  # Create citation name strings, after a Citation is created successfully
  #  Called by 'after_create' callback
  def create_citation_name_strings
    logger.debug("===CREATE CITATION_NAME_STRINGS===")    
    logger.debug("Cached CNS= #{@citation_name_strings_cache.inspect}")
    
    #Create any initialized name_strings and save to Citation
    self.citation_name_strings = @citation_name_strings_cache if @citation_name_strings_cache
  end  
  
end
