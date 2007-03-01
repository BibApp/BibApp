class MedlineImporter < CitationImporter
  
  class << self
    def import_formats
      [:medline]
    end
  end

  def generate_attribute_hash(parsed_citation)
    r_hash = Hash.new
    return false if !self.class.import_formats.include?(parsed_citation.citation_type)
    props = parsed_citation.properties
    props.each do |key, values|
      r_key = @attr_map[key]
      next if r_key.nil? or @attr_translators[r_key].nil?
      r_val = @attr_translators[key].call(values)
      if r_val.respond_to? :keys
        r_val.each do |s_key, s_val|
          r_hash[s_key] = s_val
        end
      else
        r_hash[r_key] = r_val
      end
    end
    return r_hash
  end
  
  def initialize
    @attr_map = {
       :pt => :reftype_id,
       :ti => :title_primary,
       :au => :authors,
       :ad => :affiliations,
       :jt => :periodical_full,
       :ta => :periodical_abbrev,
       :pb => :publisher,
       :mh => :keywords,
       :ab => :abstract,
       :dp => :pub_year, # translated
       :pg => :start_page, #translated
       :vi => :volume,
       :ip => :issue,
       :is => :issn_isbn,
       :pl => :place_of_publication,
       :la => :language,
       :own => :data_source,
       :stat => :database_name,
       :pmid => :identifying_phrase,
       :aid => :links
    }
  
    @attr_translators = Hash.new(lambda { |val_arr| val_arr.join("|") })
    @attr_translators[:pt] = lambda { |val_arr| @reftype_map[val_arr[0]] }
    @attr_translators[:pg] = lambda { |val_arr| page_range_parse(val_arr[0])}
    @attr_translators[:dp] = lambda { |val_arr| publication_date_parse(val_arr[0])}
    @attr_translators[:is] = lambda { |val_arr| issn_parse(val_arr[0])}

    @reftype_map = {
      "ABST"            => 2,  # Abstract
      "ADVS"            => 0,  # Audiovisual material
      "ART"             => 15, # Art work
      "BILL"            => 29, # Bill/Resolution
      "BOOK"            => 3,  # Book, whole
      "CASE"            => 26, # Case
      "CHAP"            => 4,  # Book chapter
      "COMP"            => 30, # Computer program
      "CONF"            => 5,  # Conference proceeding
      "CTLG"            => 0, # Catalog
      "DATA"            => 0,  # Data file
      "ELEC"            => 11, # Electronic citation
      "GEN"             => 0,  # Generic
      "HEAR"            => 27, # Hearing
      "ICOMM"           => 22, # Internet communication
      "INPR"            => 24, # In Press
      "JFULL"           => 1,  # Journal (full)
      "Journal Article" => 1,  # Journal
      "MAP"             => 18, # Map
      "MGZN"            => 17, # Magazine
      "MPCT"            => 19, # Motion picture
      "MUSIC"           => 20, # Music score
      "NEWS"            => 12, # Newspaper
      "PAMP"            => 0,  # Pamphlet
      "PAT"             => 6,  # Patent
      "PCOMM"           => 22, # Personal communication
      "RPRT"            => 7,  # Report
      "SER"             => 1,  # Serial (Book, Monograph)
      "SLIDE"           => 0,  # Slide
      "SOUND"           => 21, # Sound recording
      "STAT"            => 28, # Statute
      "THES"            => 14, # Thesis/Dissertation
      "UNBILL"          => 29, # Unenacted bill/resolution
      "UNPB"            => 24, # Unpublished work
      "VIDEO"           => 16 # Video recording
    }
  end
  
  def publication_date_parse(publication_date)
    date = Hash.new
    date[:pub_year] = publication_date.slice(0..3)
    return date
  end
  
  
  def page_range_parse(range)
    page_range = Hash.new
    pages = range.split("-")
    page_range[:start_page] = pages[0]
    page_range[:end_page]   = pages[1]
    return page_range
  end
  
  def issn_parse(issn)
    identifier = Hash.new
    identifier[:issn_isbn] = issn.split(/ /)[0]
    return identifier
  end
end