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
    @attr_translators[:ti] = lambda { |val_arr| strip_line_breaks(val_arr[0])}
    @attr_translators[:ab] = lambda { |val_arr| strip_line_breaks(val_arr[0])}
    @attr_translators[:ad] = lambda { |val_arr| strip_line_breaks(val_arr[0])}
    @attr_translators[:jt] = lambda { |val_arr| strip_line_breaks(val_arr[0])}
    @attr_translators[:ta] = lambda { |val_arr| strip_line_breaks(val_arr[0])}

    @type_map = {                         
      "ABST"                              => "Abstract",  # Abstract
      "ADVS"                              => "Generic",  # Audiovisual material
      "ART"                               => "ArtWork", # Art work
      "BILL"                              => "BillResolution", # Bill/Resolution
      "BOOK"                              => "Book",  # Book, whole
      "CASE"                              => "Case", # Case
      "CHAP"                              => "BookChapter",  # Book chapter
      "COMP"                              => "ComputerProgram", # Computer program
      "CONF"                              => "ConferenceProceeding",  # Conference proceeding
      "CTLG"                              => "Generic",  # Catalog
      "DATA"                              => "Generic",  # Data file
      "ELEC"                              => "ElectronicCitation", # Electronic citation
      "GEN"                               => "Generic",  # Generic
      "HEAR"                              => "Hearing", # Hearing
      "ICOMM"                             => "InternetCommunication", # Internet communication
      "INPR"                              => "InPress", # In Press
      "JFULL"                             => "JournalArticle",  # Journal (full)
      "JOUR"                              => "JournalArticle",  # Journal
      "MAP"                               => "Map", # Map
      "MGZN"                              => "Magazine", # Magazine
      "MPCT"                              => "MotionPicture", # Motion picture
      "MUSIC"                             => "MusicScore", # Music score
      "NEWS"                              => "Newspaper", # Newspaper
      "PAMP"                              => "Generic",  # Pamphlet
      "PAT"                               => "Patent",  # Patent
      "PCOMM"                             => "PersonalCommunication", # Personal communication
      "RPRT"                              => "Report",  # Report
      "SER"                               => "JournalArticle",  # Serial (Book, Monograph)
      "SLIDE"                             => "Generic",  # Slide
      "SOUND"                             => "SoundRecording", # Sound recording
      "STAT"                              => "Statute", # Statute
      "THES"                              => "ThesisDissertation", # Thesis/Dissertation
      "UNBILL"                            => "UnenactedBillResolution", # Unenacted bill/resolution
      "UNPB"                              => "UnpublishedWork", # Unpublished work
      "VIDEO"                             => "VideoRecording", # Video recording
      "Abbreviations"  => "Generic",
      "Abstracts"  => "Abstract",
      "Academic Dissertations"  => "DissertationThesis",
      "Account Books"  => "Generic",
      "Addresses"  => "Generic",
      "Advertisements"  => "Generic",
      "Almanacs"  => "Generic",
      "Anecdotes"  => "Generic",
      "Animation"  => "Generic",
      "Annual Reports"  => "Report",
      "Aphorisms and Proverbs"  => "Generic",
      "Architectural Drawings"  => "Generic",
      "Atlases"  => "BookEdited",
      "Bibliography"  => "Generic",
      "Biobibliography"  => "Generic",
      "Biography"  => "BookWhole",
      "Book Illustrations"  => "Generic",
      "Book Reviews"  => "JournalArticle",
      "Bookplates"  => "Generic",
      "Broadsides"  => "Generic",
      "Caricatures"  => "Generic",
      "Cartoons"  => "Generic",
      "Case Reports"  => "Report",
      "Catalogs"  => "Generic",
      "Charts"  => "Generic",
      "Chronology"  => "Generic",
      "Classical Article"  => "Generic",
      "Clinical Conference"  => "Generic",
      "Clinical Trial"  => "Generic",
      "Clinical Trial, Phase I"  => "Generic",
      "Clinical Trial, Phase II"  => "Generic",
      "Clinical Trial, Phase III"  => "Generic",
      "Clinical Trial, Phase IV"  => "Generic",
      "Collected Correspondence"  => "Generic",
      "Collected Works"  => "Generic",
      "Collections"  => "Generic",
      "Comment"  => "Generic",
      "Comparative Study"  => "Generic",
      "Congresses"  => "Generic",
      "Consensus Development Conference"  => "Generic",
      "Consensus Development Conference, NIH"  => "Generic",
      "Controlled Clinical Trial"  => "Generic",
      "Corrected and Republished Article"  => "Generic",
      "Database"  => "Generic",
      "Diaries"  => "Generic",
      "Dictionary"  => "Generic",
      "Directory"  => "Generic",
      "Documentaries and Factual Films"  => "Generic",
      "Drawings"  => "Generic",
      "Duplicate Publication"  => "Generic",
      "Editorial"  => "Generic",
      "Encyclopedias"  => "Generic",
      "English Abstract"  => "Generic",
      "Ephemera"  => "Generic",
      "Essays"  => "Generic",
      "Eulogies"  => "Generic",
      "Evaluation Studies"  => "Generic",
      "Examination Questions"  => "Generic",
      "Exhibitions"  => "Generic",
      "Festschrift"  => "Generic",
      "Fictional Works"  => "Generic",
      "Forms"  => "Generic",
      "Funeral Sermons"  => "Generic",
      "Government Publications"  => "Generic",
      "Guidebooks"  => "Generic",
      "Guideline"  => "Generic",
      "Handbooks"  => "Generic",
      "Herbals"  => "Generic",
      "Historical Article"  => "Generic",
      "Humor"  => "Generic",
      "In Vitro"  => "Generic",
      "Indexes"  => "Generic",
      "Instruction"  => "Generic",
      "Interactive Tutorial"  => "Generic",
      "Interview"  => "Generic",
      "Introductory Journal Article"  => "Generic",
      "Journal Article"  => "JournalArticle",
      "Juvenile Literature"  => "Generic",
      "Laboratory Manuals"  => "Generic",
      "Lecture Notes"  => "Generic",
      "Lectures"  => "Generic",
      "Legal Cases"  => "CourtCaseDecision",
      "Legislation"  => "LawStatutes",
      "Letter"  => "Generic",
      "Manuscripts"  => "Generic",
      "Maps"  => "Map",
      "Meeting Abstracts"  => "Abstract",
      "Meta-Analysis"  => "Generic",
      "Monograph"  => "Monograph",
      "Multicenter Study"  => "Generic",
      "News"  => "Generic",
      "Newspaper Article"  => "NewspaperArticle",
      "Nurses' Instruction"  => "Generic",
      "Outlines"  => "Generic",
      "Overall"  => "Generic",
      "Patents"  => "Patent",
      "Patient Education Handout"  => "Generic",
      "Periodical Index"  => "Generic",
      "Periodicals"  => "Generic",
      "Personal Narratives"  => "Generic",
      "Pharmacopoeias"  => "Generic",
      "Phrases"  => "Generic",
      "Pictorial Works"  => "Generic",
      "Popular Works"  => "Generic",
      "Portraits"  => "Generic",
      "Posters"  => "Generic",
      "Practice Guideline"  => "Generic",
      "Price Lists"  => "Generic",
      "Problems and Exercises"  => "Generic",
      "Programmed Instruction"  => "Generic",
      "Programs"  => "Generic",
      "Prospectuses"  => "Generic",
      "Publication Components"  => "Generic",
      "Publication Formats"  => "Generic",
      "Published Erratum"  => "Generic",
      "Randomized Controlled Trial"  => "Generic",
      "Research Support, N.I.H., Extramural"  => "JournalArticle",
      "Research Support, N.I.H., Intramural"  => "JournalArticle",
      "Research Support, Non-U.S. Gov't"  => "JournalArticle",
      "Research Support, U.S. Gov't, Non-P.H.S."  => "JournalArticle",
      "Research Support, U.S. Gov't, P.H.S."  => "JournalArticle",
      "Resource Guides"  => "Generic",
      "Retracted Publication"  => "Generic",
      "Retraction of Publication"  => "Generic",
      "Review"  => "Generic",
      "Scientific Integrity Review"  => "Generic",
      "Sermons"  => "Generic",
      "Statistics"  => "Generic",
      "Study Characteristics"  => "Generic",
      "Support of Research"  => "Generic",
      "Tables"  => "Generic",
      "Technical Report"  => "Generic",
      "Terminology"  => "Generic",
      "Textbooks"  => "Generic",
      "Twin Study"  => "Generic",
      "Unedited Footage"  => "Generic",
      "Union Lists"  => "Generic",
      "Unpublished Works"  => "Generic",
      "Validation Studies"  => "Generic"
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
  
  def strip_line_breaks(value)
    clean = value.gsub(/\s+/, " ")
    return clean
  end
end