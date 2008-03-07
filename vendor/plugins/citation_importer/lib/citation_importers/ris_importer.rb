class RisImporter < CitationImporter
  
  class << self
    def import_formats
      [:ris]
    end
  end

  def generate_attribute_hash(parsed_citation)
    r_hash = Hash.new
    return false if !self.class.import_formats.include?(parsed_citation.citation_type)
    props = parsed_citation.properties
    props.each do |key, values|
      
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
      
      if value.size < 2 || value.class.to_s == "String"
        r_hash[key] = value.to_s
      end
      
      if value.size >= 2 && value.class.to_s == "Array"
        r_hash[key] = value.flatten
      end
    end
    
    return r_hash
  end
  
  def initialize
    # Todo: improve Publication and Publisher handling
    @attr_map = {
       :ty => :klass,
       :t1 => :title_primary,
       :ti => :title_primary,
       :bt => :title_secondary,
       :t3 => :title_tertiary,
       :a1 => :name_strings,
       :ed => :name_strings,
       :ad => :affiliation,
       :jf => :publication,
       :ja => :publication,
       :jo => :publication,
       :pb => :publisher,
       :kw => :keywords,
       :u2 => :keywords,
       :n2 => :abstract,
       :y1 => :year,
       :py => :year,
       :sp => :start_page,
       :ep => :end_page,
       :vl => :volume,
       :is => :issue,
       :sn => :issn_isbn,
       :cy => :publication_place,
       :bn => :issn_isbn,
       :n1 => :notes,
       :m1 => :notes,
       :l2 => :links,
       :original_data => :original_data
    }
  
    @attr_translators = Hash.new(lambda { |val_arr| val_arr.to_a })
    @attr_translators[:ty] = lambda { |val_arr| @type_map[val_arr[0]].to_a }
    @attr_translators[:py] = lambda { |val_arr| publication_date_parse(val_arr[0])}
    
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
    date[:year] = publication_date.split(/[^A-Za-z0-9_]/)[0]
    return date
  end
  
end