class Citation < ActiveRecord::Base
  require 'htmlentities'
  
  #### Associations ####
  belongs_to :publication
  belongs_to :publisher
  has_many :name_strings, 
    :through => :citation_name_strings, 
    :order => :position
  has_many :citation_name_strings
  
  has_many :people,
    :through => :contributorships
  has_many :contributorships
  
  has_many :keywords, :through => :keywordings
  has_many :keywordings
  
  has_many :files, :as => :asset

  #### Callbacks ####
  before_validation_on_create :set_initial_states

  def after_create 
   	create_citation_name_strings
  	create_keywords
    create_publisher
    #save any changes to citation
    self.save_without_callbacks
  end
  
  def after_save
    deduplicate
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
		"Journal Article", 
		"Conference Proceeding", 
		"Book (Whole)"		
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
      logger.debug "Saving dupe citation_states"
      dupe.citation_state_id = 2 unless dupe.citation_state_id == 3
      dupe.save_without_callbacks
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

  # Batch import Citations
  def self.import_batch!(data)    
    
    # Read the data
    str = data
    if data.respond_to? :read
      str = data.read
    elsif File.readable?(data)
      str = File.read(data)
    end
    
    # Init: Parser and Importer
    p = CitationParser.new
    i = CitationImporter.new

    # Parse the data
    pcites = p.parse(str)
    logger.debug("\n\nParsed Citations: #{pcites.size}\n\n")
    return nil if pcites.nil?
    
    # Map Import hashes
    attr_hashes = i.citation_attribute_hashes(pcites)
    logger.debug "#{attr_hashes.size} Attr Hashes: #{attr_hashes.inspect}\n\n\n"
    
    return [] if attr_hashes.nil?
    all_cites = attr_hashes.map { |h|
      
      # Initialize the Citation
      klass = h[:klass]
      
      # Are we working with a legit SubKlass?
      klass = klass.constantize
      if klass.superclass != Citation
        raise NameError.new("#{klass_type} is not a subclass of Citation") and return
      end
      citation = klass.new
      
      # Setting CitationNameStrings
      citation_name_strings = h[:citation_name_strings]
      citation.citation_name_strings = citation_name_strings
      
      # Setting publisher
      citation.publisher_name = h[:publisher]
      
      # Setting publication_id
      # If there is no publication data, set publication to Unknown
      if h[:publication].nil? || h[:publication].empty?
        h[:publication] = "Unknown"
      end
      
      publication = Array.new
      h[:publication].each do |add|
        publication = Publication.find_or_create_by_name_and_issn_isbn(
          :name => add, 
          :issn_isbn => h[:issn_isbn], 
          :publisher_id => h[:publisher_id]
        )
        h[:publication_id] = publication.authority_id
      end
      
      # Setting keywords
      citation.keyword_strings = h[:keywords]
	  
      
      # Clean the abstract
      # @TODO we'll want to clean all data
      code = HTMLEntities.new
      h[:abstract] = code.encode(h[:abstract], :decimal)
      
      # Clean the hash of non-Citation table data
      # Cleaning preps hash for AR insert
      h.delete(:klass)
      h.delete(:citation_name_strings)
      h.delete(:publisher)
      h.delete(:publication)
      h.delete(:publication_place)
      h.delete(:issn_isbn)
      h.delete(:keywords)
      h.delete(:source)
      # @TODO add external_systems to citation import
      h.delete(:external_id)

      #save remaining hash attributes
      citation.attributes=h
      citation.issn_isbn_dupe_key = self.set_issn_isbn_dupe_key(citation, citation_name_strings, publication)
      citation.title_dupe_key = self.set_title_dupe_key(citation)
      citation.save_and_set_for_index
    }
    Index.batch_index
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
  
  # Initializes the Publisher 
  # and saves it to the current citation
  # Arguments:
  #  * publisher name (as a string)
  def publisher_name=(publisher_name)
    logger.debug("\n\n===SET PUBLISHER NAME===\n\n")
    logger.debug("Publisher NAME= #{publisher_name.inspect}")
    # Setting publisher_id
    # If there is no publisher data, set publisher to Unknown
    if publisher_name.nil? || publisher_name.empty?
      publisher_name = "Unknown"
    end
      
    #initialize and save or update citation
    self.publisher = Publisher.find_or_initialize_by_name(publisher_name)   
  end
  
  # Updates publisher for the current citation
  # If this citation is still a *new* record (i.e. it hasn't been created
  # in the database), then the publisher is just cached until the 
  # citation is created.
  # Based on ideas at:
  #   http://blog.hasmanythrough.com/2007/1/22/using-faux-accessors-to-initialize-values
  #
  # Arguments:
  #  * Publisher object
  def publisher=(publisher)
    logger.debug("\n\n===SET PUBLISHER===\n\n")
    logger.debug("Publisher= #{publisher.inspect}")
    if self.new_record?
      #Defer saving to Citation object directly, until it is created
      @publisher_cache = publisher
    else
      # Create publisher and save to database
      Citation.update_publisher(self, publisher)  
    end
  end  
  
 
  # All Citations begin unverified
  def set_initial_states
    self.citation_state_id = 1
    self.citation_archive_state_id = 1
  end

  def solr_id
    "Citation:#{id}"
  end

  def self.set_issn_isbn_dupe_key(citation, citation_name_strings, publication)
    # Set issn_isbn_dupe_key
    logger.debug("\nCNS: #{citation_name_strings.inspect}\n")
    if citation_name_strings
      first_author = citation_name_strings[0][:name].split(",")[0]
    else
      first_author = nil
    end
        
    if (first_author.nil? or publication.issn_isbn.nil? or citation.year.nil? or citation.year.empty? or citation.start_page.nil? or citation.start_page.empty? or publication.issn_isbn.empty?)
      issn_isbn_dupe_key = nil
    else
      issn_isbn_dupe_key = (first_author+publication.issn_isbn+citation.year.to_s+citation.start_page.to_s).gsub(/[^0-9A-Za-z]/, '').downcase
    end
  end
    
  def self.set_title_dupe_key(citation)
    # Set title_dupe_key      
    if citation.title_primary.nil? or citation.year.nil? or citation[:type].nil? or citation.start_page.nil?
      title_dupe_key = nil
    else 
      title_dupe_key = citation.title_primary.downcase.gsub(/[^a-z]/,'')+citation.year.to_s+citation[:type].to_s+citation.start_page.to_s
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
        citation.citation_name_strings << 
          CitationNameString.new({
            :name_string_id => name_string.id, 
            :role => cns[:role]
          })
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
  
  
  # Update Publisher - updates publisher for citation
  # Arguments:
  #   - citation object
  #   - Publisher objects
  def self.update_publisher(citation, publisher)
    logger.debug("\n\n===UPDATE PUBLISHER===\n\n")
    unless publisher.nil?
      #if this is a brand new publisher, we must save it first
      if publisher.new_record?
        publisher.save
      end
      
      #save publisher's authority_id to this citation
      citation.publisher_id = publisher.authority_id
    end #end unless no publisher

    logger.debug("Citation Publisher Saved= #{citation.publisher.inspect}")
  end   
  
  # Create publisher, after a Citation is created successfully
  #  Called by 'after_create' callback
  def create_publisher
    logger.debug("===CREATE PUBLISHER===") 
    logger.debug("Cached Publisher= #{@publisher_cache.inspect}")
    #Create any initialized publisher and save to Citation
    self.publisher = @publisher_cache if @publisher_cache
  end  
  
 
end
