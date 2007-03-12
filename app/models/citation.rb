class Citation < ActiveRecord::Base    
  acts_as_taggable

  before_validation_on_create :set_initial_state

  before_save   :compute_index_keys
  before_save   :set_publication
  
  after_save :tag_with_keywords
  
  has_many :authorships
  has_many :people,
    :through => :authorships
    
  belongs_to :citation_state
  belongs_to :archive_status
  belongs_to :reftype
  belongs_to :publication
  
  validates_associated :citation_state
  validates_associated :archive_status
  
  validates_presence_of :authors
  validates_presence_of :title_primary

  def to_s
    "<h4>#{reftype.refworks_reftype}<\/h4> #{title_primary.titleize} <br \/> #{authors.gsub(/,/, ', ').gsub(/\|/, ', ')} <br \/> (#{pub_year}) . #{periodical_full} [#{volume}:#{issue}] #{start_page} - #{end_page}"
  end

  def self.find_all_by_tag_or_person_id(tag, person_id)
    condpart = Array.new
    criteria = Array.new
    condpart << 't.name = ?' if tag
    condpart << 'au.person_id = ?' if person_id
    condpart << 'c.citation_state_id = 3'
  
    criteria << tag if tag
    criteria << person_id if person_id
  
    # Generates something like tag.name = ? and person_id = ?
    # Or, tag.name = ?
    conditions = condpart.join(' and ')
  
    self.find(:all, :select => "distinct c.*", :conditions => [conditions, criteria].flatten, 
      :joins => 
        "as c join taggings tg on c.id = tg.taggable_id
        join tags t on t.id = tg.tag_id
        join authorships au on au.citation_id = c.id",
      :order => "c.pub_year DESC, c.title_primary")
  end
  
  def ref_class
    self.reftype.nil? ? "" : self.reftype.class_name
  end

  def tag_with_keywords
    return unless needs_retagging?
    kw = keywords || ""
    tags = kw.split('|')
    tags.each do |tag|
      # Supertrim - don't allow anything but alphanum at start or end of tag
      tag = tag.downcase.gsub(/(^[^a-z0-9]+)|([^a-z0-9]+$)/, '')
      # And replace all nonalphanums with '-'
      tag = tag.gsub(/[^a-z0-9]+/, '-')
      # And don't tag with anything too short
      tag_with(tag) unless tag.length < 3
    end
    set_original_keywords
  end

  def set_initial_state
    citation_state_id = 1
  end

  def issn_dupe_key
    if (authors.nil? or issn_isbn.nil? or pub_year.nil? or start_page.nil? or issn_isbn.empty?)
      nil
    else
      (authors.split(",")[0] + issn_isbn + pub_year.to_s + start_page.to_s).gsub(/[^0-9A-Za-z]/, '').downcase
    end
  end

  def title_dupe_key
    return nil if title_primary.nil? or pub_year.nil? or reftype_id.nil? or start_page.nil?
    title_primary.downcase.gsub(/[^a-z]/,'')+pub_year.to_s+reftype_id.to_s+start_page.to_s
  end

  def compute_index_keys
    write_attribute("issn_dupe_key", issn_dupe_key)
    write_attribute("title_dupe_key", title_dupe_key)
  end

  def duplicates
    # This is Very Slow (at least on mysql) when done in one query with an OR:
    # mysql will only use one index per query, and the or implies that your index 
    # would need to be indexed with more than one key first.
    # Alternative approach: use find_by_sql and UNION
    issn_dupes = Citation.find(:all, 
      :conditions => ["citation_state_id <> 2 and issn_dupe_key = ?", issn_dupe_key])
    title_dupes = Citation.find(:all, 
      :conditions => ["citation_state_id <> 2 and title_dupe_key = ?", title_dupe_key])
    
    return (issn_dupes + title_dupes).uniq
  end

  # The highest score will win... currently, we like things from Engineering Village folders,
  # and really like things that are already accepted.
  def preferred_score
    score = 0
    #score = 1 if (folder["- ev"])
    score = 10 if citation_state_id == 3
    score
  end



  def self.import_batch!(data)    
    str = data
    if data.respond_to? :read
      str = data.read
    elsif File.readable?(data)
      str = File.read(data)
    end
    p = CitationParser.new
    i = CitationImporter.new
    pcites = p.parse(str)
    return nil if pcites.nil?
    
    attr_hashes = i.citation_attribute_hashes(pcites)
    return [] if attr_hashes.nil?
    all_cites = attr_hashes.map { |h| Citation.create(h) }
    valid_cites, invalid_cites = all_cites.partition { |c| c.valid? }
    return deduplicate(valid_cites)
  end
    
  def self.deduplicate(to_add)
    begin
      Citation.transaction do
        new_list = Array.new
        to_add.each do |citation|
          # Pick up changes (flagging as duplicate, etc) that might have happened here
          citation.reload
          next if citation.citation_state_id == 2 # Don't reprocess dupes
          dupe_candidates = citation.duplicates
          if dupe_candidates.size < 2
            citation.citation_state_id = 3
            citation.save
            new_list << citation
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
            new_list << best unless new_list.include?(best)
          end
      
          # All the others are, by definition, dupes
          dupe_candidates.each do |dupe|
            dupe.citation_state_id = 2 unless dupe.citation_state_id == 3
            dupe.save
          end
        end
        new_list
      end
    end
  end
  
  def after_find
    set_original_keywords
  end
  
  def set_original_keywords
    @original_keywords = self.keywords
  end

  def needs_retagging?
    self.citation_state_id == 3 and self.keywords != @original_keywords
  end
  
  # Authors formatted like 'foo,a|bar,b|baz,c'
  # become ['foo, a', 'bar, b', 'baz, c']
  def author_array
    authors.split('|').map { |a| a.gsub(/,(?=\S)/, ', ') }        
  end
  
  def set_publication
    self.publication = Publication.find_by_issn_isbn(self.issn_isbn)
  end
  
end
