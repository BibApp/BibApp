class Citation < ActiveRecord::Base  
  #### Associations ####
  belongs_to :publication
  belongs_to :publisher
  has_many :author_strings, 
    :through => :citation_author_strings, 
    :order => :position
  has_many :citation_author_strings
  
  has_many :people,
    :through => :authorships
  has_many :authorships
  
  has_many :keywords, :through => :keywordings
  has_many :keywordings

  #### Callbacks ####
  before_validation_on_create :set_initial_states
  after_create :create_author_strings
  
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
		"Book"		
	]  
  end
  
  
  # Deduplication: deduplicate Citation records on create
  def self.deduplicate(citation)
    logger.debug("\n\n===DEDUPLICATE===\n\n")
    begin
      Citation.transaction do
        dupe_candidates = duplicates(citation)

        if dupe_candidates.empty?
          citation.citation_state_id = 3
          citation.save_without_callbacks
          next
        end
                  
        if dupe_candidates.size < 2
          citation.citation_state_id = 3
          citation.save_without_callbacks
          next
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
        end
    
        # All the others are, by definition, dupes
        dupe_candidates.each do |dupe|
          logger.debug "Saving dupe citation_states"
          dupe.citation_state_id = 2 unless dupe.citation_state_id == 3
          dupe.save_without_callbacks
        end
      end
    end
  end

  # Deduplication: search for Citation duplicates
  def self.duplicates(citation)
    # This is Very Slow (at least on mysql) when done in one query with an OR:
    # mysql will only use one index per query, and the or implies that your index 
    # would need to be indexed with more than one key first.
    # Alternative approach: use find_by_sql and UNION
    logger.debug("\n\nCitation: #{citation.inspect}\n\n")
    issn_dupes = Citation.find(:all, 
      :conditions => ["citation_state_id <> 2 and issn_isbn_dupe_key = ?", citation.issn_isbn_dupe_key])
    title_dupes = Citation.find(:all, 
      :conditions => ["citation_state_id <> 2 and title_dupe_key = ?", citation.title_dupe_key])
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
    return nil if pcites.nil?
    
    # Map Import hashes
    attr_hashes = i.citation_attribute_hashes(pcites)
    logger.debug "#{attr_hashes.size} Attr Hashes: #{attr_hashes.inspect}\n\n\n"
    
    return [] if attr_hashes.nil?
    all_cites = attr_hashes.map { |h|
      
      # Setting author_strings
      author_strings = Array.new
      h[:author_strings].each do |add|
        author_string = AuthorString.find_or_create_by_name(add)
        author_strings << author_string
      end

      # Setting publisher_id
      # If there is no publisher data, set publisher to Unknown
      if h[:publisher].nil? || h[:publisher].empty?
        h[:publisher] = "Unknown"
      end
      
      h[:publisher].each do |add|
        publisher = Publisher.find_or_create_by_name(add)
        h[:publisher_id] = publisher.authority_id
      end
      
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
      keywords = Array.new
      h[:keywords].each do |add|
        keyword = Keyword.find_or_create_by_name(add)
        keywords << keyword
      end

      # Create the Citation
      klass = h[:klass]
        
      # Are we working with a legit SubKlass?
      klass = klass.constantize
      if klass.superclass != Citation
        raise NameError.new("#{klass_type} is not a subclass of Citation") and return
      end
      
      # Clean the hash of non-Citation table data
      # Cleaning preps hash for AR insert
      h.delete(:klass)
      h.delete(:author_strings)
      h.delete(:publisher)
      h.delete(:publication)
      h.delete(:publication_place)
      h.delete(:issn_isbn)
      h.delete(:keywords)
      h.delete(:source)

      citation = klass.create(h)
      citation.issn_isbn_dupe_key = self.set_issn_isbn_dupe_key(citation, author_strings, publication)
      citation.title_dupe_key = self.set_title_dupe_key(citation)
      citation.save_and_set_for_index_without_callbacks
      deduplicate(citation)
      citation.author_strings = author_strings
      set_keywordings(citation, keywords)
    }
    Index.batch_index
  end

  # Set Keywordings
  def self.set_keywordings(citation, keywords)
    logger.debug("\n\n===SET KEYWORDINGS===\n\n")
    keywords.each do |keyword|
      Keywording.find_or_create_by_citation_id_and_keyword_id(:citation_id => citation.id, :keyword_id => keyword.id)
    end
  end
  
  #Updates author_strings for the current citation
  # 	If this citation is still a *new* record (i.e. it hasn't been created
  # 	in the database), then the author_strings are just cached until the 
  #  	citation is created.
  #     Based on ideas at:
  #			http://blog.hasmanythrough.com/2007/1/22/using-faux-accessors-to-initialize-values
  def author_strings=(author_strings)
	logger.debug("\n\n===SET CITATION_AUTHOR_STRINGS===\n\n")
  
	if self.new_record?
		#Defer saving to Citation object directly, until it is created
		@author_strings = author_strings
	else
	  	# Create author_strings and save to database
		Citation.update_citation_author_strings(self, author_strings)  
	end
  end  
  
  # Update CitationAuthorStrings - updates list of authors for citation
  def self.update_citation_author_strings(citation, author_strings)
  	logger.debug("\n\n===UPDATE CITATION_AUTHOR_STRINGS===\n\n")
	  
	unless author_strings.nil?
		#first, remove any author_string(s) that are no longer in list
		citation.citation_author_strings.each do |cas|
			cas.destroy unless author_strings.include?(cas.author_string)
			author_strings.delete(cas.author_string)
		end 
		#next, add any new author string(s) to list
		author_strings.each do |author_string|
			CitationAuthorString.find_or_create_by_citation_id_and_author_string_id(:citation_id => citation.id, :author_string_id => author_string.id)
		end
		#refresh citation in memory based on database updates
		citation.reload
	end	  
  end    
  
  # Create author strings, after a Citation is created successfully
  #  Called by 'after_create' callback
  def create_author_strings
  	#Create any initialized author_strings and save to Citation
  	self.author_strings = @author_strings if @author_strings
  end  
  
  
=begin
  # Set Dupe Keys
  def self.set_dupe_keys(citation, author_strings, publication)
    logger.debug("\n\n===SET DUPE KEYS===\n\n")
    logger.debug("Citation: #{citation.inspect}\n\n")
    logger.debug("AuthorStrings: #{author_strings.inspect}\n\n")
    logger.debug("Publication: #{publication.inspect}\n\n")
    self.write_attribute("issn_isbn_dupe_key", self.issn_isbn_dupe_key(citation, author_strings, publication))
    self.write_attribute("title_dupe_key", self.title_dupe_key(citation))
  end
=end

  # All Citations begin unverified
  def set_initial_states
    self.citation_state_id = 1
    self.citation_archive_state_id = 1
  end

  def solr_id
    "Citation:#{id}"
  end

  def self.set_issn_isbn_dupe_key(citation, author_strings, publication)
    # Set issn_isbn_dupe_key
    if author_strings
      first_author = author_strings[0].name.split(",")[0]
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
 
end
