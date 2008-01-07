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
      puts "Key: #{key}\n"
      puts "Value: #{values} | #{values.class}\n\n"
      
      # Key
      r_key = @attr_map[key]
      next if r_key.nil? or @attr_translators[r_key].nil?
      # Value
      r_val = @attr_translators[key].call(values)
      
      if r_val.respond_to? :keys
        r_val.each do |s_key, s_val|
          r_hash[s_key] = s_val
        end
      else
        if r_hash.has_key?(r_key)
          r_hash[r_key] = r_hash[r_key].to_a << r_val
          next
        end
        r_hash[r_key] = r_val
      end
      r_hash["original_data"] = props["original_data"]
    end

    r_hash.each do |key, value|
      if value and value.size < 2
        r_hash[key] = value.to_s
      end
      
      if value.class.to_s == "String" || "Fixnum"
        # Do nothing, we're already flat.
      else 
        r_hash[key] = value.flatten
      end
    end
    
    puts "Mapped Hash: #{r_hash.inspect}"
    return r_hash
  end
  
  def initialize
    @attr_map = {
       :pt => :klass,
       :ti => :title_primary,
       :au => :authors,
       :ad => :affiliation,
       :jt => :publication,
       :ta => :publication,
       :pb => :publisher,
       :mh => :keywords,
       :ab => :abstract,
       :dp => :year, # translated
       :pg => :start_page, #translated
       :vi => :volume,
       :ip => :issue,
       :is => :issn_isbn,
       :pl => :publication_place,
       :own => :source,
       :stat => :notes,
       :pmid => :external_id,
       :aid => :links,
       :original_data => :original_data
    }
  
    @attr_translators = Hash.new(lambda { |val_arr| val_arr.to_a })
    @attr_translators[:pt] = lambda { |val_arr| @type_map[val_arr[0]] }
    @attr_translators[:pg] = lambda { |val_arr| page_range_parse(val_arr[0])}
    @attr_translators[:dp] = lambda { |val_arr| publication_date_parse(val_arr[0])}
    @attr_translators[:is] = lambda { |val_arr| issn_parse(val_arr[0])}

    @type_map = {
      "ABST"  => "Abstract",  # Abstract
      "ADVS"  => "Generic",  # Audiovisual material
      "ART"   => "ArtWork", # Art work
      "BILL"  => "BillResolution", # Bill/Resolution
      "BOOK"  => "Book",  # Book, whole
      "CASE"  => "Case", # Case
      "CHAP"  => "BookChapter",  # Book chapter
      "COMP"  => "ComputerProgram", # Computer program
      "CONF"  => "ConferenceProceeding",  # Conference proceeding
      "CTLG"  => "Generic",  # Catalog
      "DATA"  => "Generic",  # Data file
      "ELEC"  => "ElectronicCitation", # Electronic citation
      "GEN"   => "Generic",  # Generic
      "HEAR"  => "Hearing", # Hearing
      "ICOMM" => "InternetCommunication", # Internet communication
      "INPR"  => "InPress", # In Press
      "JFULL" => "JournalArticle",  # Journal (full)
      "JOUR"  => "JournalArticle",  # Journal
      "Journal Article" => "JournalArticle",
      "Comparative Study" => "JournalArticle",
      "Research Support, Non-U.S. Gov't" => "JournalArticle", #TODO: fix this... break
      "MAP"   => "Map", # Map
      "MGZN"  => "Magazine", # Magazine
      "MPCT"  => "MotionPicture", # Motion picture
      "MUSIC" => "MusicScore", # Music score
      "NEWS"  => "Newspaper", # Newspaper
      "PAMP"  => "Generic",  # Pamphlet
      "PAT"   => "Patent",  # Patent
      "PCOMM" => "PersonalCommunication", # Personal communication
      "RPRT"  => "Report",  # Report
      "SER"   => "JournalArticle",  # Serial (Book, Monograph)
      "SLIDE" => "Generic",  # Slide
      "SOUND" => "SoundRecording", # Sound recording
      "STAT"  => "Statute", # Statute
      "THES"  => "ThesisDissertation", # Thesis/Dissertation
      "UNBILL"=> "UnenactedBillResolution", # Unenacted bill/resolution
      "UNPB"  => "UnpublishedWork", # Unpublished work
      "VIDEO" => "VideoRecording" # Video recording
    }
  end
  
  def publication_date_parse(publication_date)
    date = Hash.new
    date[:year] = publication_date.slice(0..3)
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