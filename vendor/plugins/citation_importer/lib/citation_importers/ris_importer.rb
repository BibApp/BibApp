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
      
      if value.class.to_s == "Array"
        value = value.flatten
      end
      
      if value[0].class.to_s == "Hash"
        r_hash[key] = value.flatten
        next
      end
      
      if value.size < 2 || value.class.to_s == "String"
        r_hash[key] = value.to_s
      end
      
      if value.size >= 2 && value.class.to_s == "Array"
        r_hash[key] = value.flatten
      end
      
    end
   # puts "\n\nMapped Hash: #{r_hash.inspect}\n\n"
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
       :a1 => :citation_name_strings,
       :ed => :citation_name_strings,
       :ad => :affiliation,
       :jf => :publication,
       :ja => :publication,
       :jo => :publication,
       :pb => :publisher,
       :kw => :keywords,
       :u2 => :keywords,
       :n2 => :abstract,
       :y1 => :publication_date,
       :py => :publication_date,
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

    # Map NameString and CitationNameStringType
    # example {:name => "Larson, EW", :type=> "Author"}
    @attr_translators[:a1] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Author"}}}
    @attr_translators[:ed] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Editor"}}}
    @attr_translators[:ty] = lambda { |val_arr| @type_map[val_arr[0]].to_a }
    @attr_translators[:py] = lambda { |val_arr| publication_date_parse(val_arr[0])}
    @attr_translators[:y1] = lambda { |val_arr| publication_date_parse(val_arr[0])}
    
    @type_map = {
       "ABST"  => "Abstract",  # Abstract
       "ADVS"  => "Generic",  # Audiovisual material
       "ART"   => "ArtWork", # Art work
       "BILL"  => "BillResolution", # Bill/Resolution
       "BOOK"  => "BookWhole",  # Book, whole
       "CASE"  => "Case", # Case
       "CHAP"  => "BookSection",  # Book chapter
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
       "THES"  => "DissertationThesis", # Thesis/Dissertation
       "UNBILL"=> "UnenactedBillResolution", # Unenacted bill/resolution
       "UNPB"  => "UnpublishedWork", # Unpublished work
       "VIDEO" => "VideoRecording" # Video recording
    }
  end
  
  def publication_date_parse(publication_date)
    
    date = Hash.new
    
    # Split on the non-word characters (in this case, should be slashes /)
    # Expected format: "YYYY/MM/DD/other info"
    date_parts = publication_date.split(/[^A-Za-z0-9_]/)
    
    if date_parts[0] != nil
      # first part is year
      year = date_parts[0].to_i
      # then month (default to Jan)
      month = 1
 #     month = date_parts[1] if !date_parts[1].nil?
      # then day (default to 1)
      day = 1
 #     day = date_parts[2] if !date_parts[2].nil?
    
      # create a date suitable for saving
      date[:publication_date] = Date.new(year,month,day).to_s
    
      return date
    else
      return nil
      
    end
  
    
    
  end
  
end