class Citation < ActiveRecord::Base  
  #### Associations ####
  belongs_to :publication
  belongs_to :publisher
  has_many :author_strings, 
    :through => :citation_author_strings, 
    :order => "position"
  has_many :citation_author_strings
  
  has_many :people,
    :through => :authorships
  has_many :authorships
  
  has_many :keywords, :through => :keywordings
  has_many :keywordings

  #### Validations ####
  before_validation_on_create :set_initial_states
  validates_presence_of :title_primary

  before_save :set_citation_author_strings
  before_save :set_dupe_keys
  after_save :deduplicate


  #### Serialization ####
  serialize :serialized_data

  ########## Methods ##########
  # Rule #1: Alphabetical please
  # Rule #2: Comment H-E-A-V-I-L-Y
  # Rule #3: Include @TODOs
  
  # Deduplication: deduplicate Citation records on create
  def deduplicate
    logger.debug("\n\n===DEDUPLICATE===\n\n")
    begin
      Citation.transaction do
        dupe_candidates = self.duplicates

        if dupe_candidates.empty?
          self.citation_state_id = 3
          self.save_without_callbacks
          next
        end
                  
        if dupe_candidates.size < 2
          self.citation_state_id = 3
          self.save_without_callbacks
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
  def duplicates
    # This is Very Slow (at least on mysql) when done in one query with an OR:
    # mysql will only use one index per query, and the or implies that your index 
    # would need to be indexed with more than one key first.
    # Alternative approach: use find_by_sql and UNION
    issn_dupes = Citation.find(:all, 
      :conditions => ["citation_state_id <> 2 and issn_isbn_dupe_key = ?", issn_isbn_dupe_key])
    title_dupes = Citation.find(:all, 
      :conditions => ["citation_state_id <> 2 and title_dupe_key = ?", title_dupe_key])
    return (issn_dupes + title_dupes).uniq
  end

  def issn_isbn_dupe_key
    # Set issn_isbn_dupe_key
    first_author = self.serialized_data[:author_strings]
    if first_author.class.name == "String"
      #Nothing - we have our primary author
    else
      first_author = first_author[0]
    end
    
    first_author = first_author.split(",")[0]
    publication = Publication.find(self.publication_id)
    
    logger.debug "First Author = #{first_author}\n"
    logger.debug "Publiction = #{publication.issn_isbn}\n"
    logger.debug "Year = #{self.year}\n"
    logger.debug "Start Page = #{self.start_page}\n"    
        
    if (first_author.nil? or publication.issn_isbn.nil? or self.year.nil? or self.year.empty? or self.start_page.nil? or self.start_page.empty? or publication.issn_isbn.empty?)
      issn_isbn_dupe_key = nil
    else
      issn_isbn_dupe_key = (first_author+publication.issn_isbn+self.year.to_s+self.start_page.to_s).gsub(/[^0-9A-Za-z]/, '').downcase
    end
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
      
      # Find or create AuthorStrings, store each AuthorSring.id to generate CitationAuthorString
      author_strings = Array.new
      citation_author_strings = Array.new

      h[:author_strings].each do |add|
        author_string = AuthorString.find_or_create_by_name(add)
        author_strings << author_string.name
        citation_author_strings << author_string.id
      end
      
      h[:author_strings_cache] = author_strings
      h[:citation_author_strings_cache] = citation_author_strings

      # Set publisher_id
      if h[:publisher].nil? || h[:publisher].empty?
        h[:publisher] = "Unknown"
      end
      
      h[:publisher].each do |add|
        publisher = Publisher.find_or_create_by_name(add)
        h[:publisher_id] = publisher.authority_id
      end
      
      # Set publication_id
      if h[:publication].nil? || h[:publication].empty?
        h[:publication] = "Unknown"
      end
      
      h[:publication].each do |add|
        publication = Publication.find_or_create_by_name_and_issn_isbn(
          :name => add, 
          :issn_isbn => h[:issn_isbn], 
          :publisher_id => h[:publisher_id]
        )
        
        h[:publication_id] = publication.authority_id
      end
      
      # Create the Citation
      klass = h[:klass]
        
      # Are we working with a legit SubKlass?
      klass = klass.constantize
      if klass.superclass != Citation
        raise NameError.new("#{klass_type} is not a subclass of Citation") and return
      end

      # Prepare serialized_data Hash      
      s = Hash.new

      h.each do |k, v|
        s[k] = v
      end
      
      h[:serialized_data] = s
      
      # Clean the hash of non-Citation table data
      # Cleaning preps hash for AR insert
      h.delete(:klass)
      h.delete(:author_strings)
      h.delete(:author_strings_cache)
      h.delete(:citation_author_strings_cache)
      h.delete(:publisher)
      h.delete(:publication)
      h.delete(:publication_place)
      h.delete(:issn_isbn)
      h.delete(:keywords)
      h.delete(:source)

      citation = klass.create(h)
    }
    
    valid_cites, invalid_cites = all_cites.partition { |c|  c.title_primary? }

    # @TODO: STI breaks AR base method .valid?... WTF?
    valid_cites.each do |vc|
      vc.save
    end
    #return deduplicate(valid_cites)
  end

  # CitationAuthorStrings
  def set_citation_author_strings
    logger.debug("\n\n===SET CITATION_AUTHOR_STRINGS===\n\n")
    self.serialized_data[:citation_author_strings_cache].each do |a|
      CitationAuthorString.find_or_create_by_citation_id_and_author_string_id(:citation_id => self.id, :author_string_id => a)
    end
  end

  def set_dupe_keys
    logger.debug("\n\n===SET DUPE KEYS===\n\n")
    write_attribute("issn_isbn_dupe_key", issn_isbn_dupe_key)
    write_attribute("title_dupe_key", title_dupe_key)
  end

  # All Citations begin unverified
  def set_initial_states
    self.citation_state_id = 1
    self.citation_archive_state_id = 1
  end

  def solr_id
    "Citation:#{id}"
  end
  
  def title_dupe_key
    # Set title_dupe_key      
    if self.title_primary.nil? or self.year.nil? or self[:type].nil? or self.start_page.nil?
      title_dupe_key = nil
    else 
      title_dupe_key = self.title_primary.downcase.gsub(/[^a-z]/,'')+self.year.to_s+self[:type].to_s+self.start_page.to_s
    end
  end
 
end
