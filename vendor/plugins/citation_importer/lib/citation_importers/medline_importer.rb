#
# Medline format importer for BibApp
# 
# Initializes attribute mapping & value translators,
# used to generate a valid BibApp attribute Hash.
# 
# For the actual processing & attribute hash creation,
# see the BaseImporter.
#
class MedlineImporter < BaseImporter
  
  attr_reader :type_mapping
  
  class << self
    def import_formats
      [:medline]
    end
  end

  #Initialize our Medline Importer  
  def initialize
    
    #Mapping of Medline Attributes => BibApp Attributes
    @attribute_mapping = {
       :pt => :klass,
       :ti => :title_primary,
       :au => :work_name_strings,
       :fau => :work_name_strings,
       :ad => :affiliation,
       :jt => :publication,
       :ta => :publication,
       :pb => :publisher,
       :mh => :keywords,
       :ab => :abstract,
       :dp => :publication_date, # translated
       :pg => :start_page, #translated
       :vi => :volume,
       :ip => :issue,
       :is => :issn_isbn,
       :pl => :publication_place,
       :own => :source,
       :stat => :notes,
       :pmid => :external_id,
       :aid => :links,
       :la  => :language,
       :ci  => :copyright_holder,
       :original_data => :original_data
    }
  
    #Initialize our Value Translators (which will translate values from normal Medline files)
    @value_translators = Hash.new(lambda { |val_arr| Array(val_arr) })
    
    # Map NameString and CitationNameStringType
    # example {:name => "Larson, EW", :role=> "Author"}
    @value_translators[:au] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Author"}}}
    @value_translators[:fau] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Author"}}}
    
    # Map publication types (see @type_mapping)    
    @value_translators[:pt] = lambda { |val_arr| @type_mapping[val_arr[0].downcase] }
    
    # Parse start/end page from page-range field
    @value_translators[:pg] = lambda { |val_arr| page_range_parse(val_arr[0])}
    
    # Parse publication date & ISSN
    @value_translators[:dp] = lambda { |val_arr| publication_date_parse(val_arr[0])}
    @value_translators[:is] = lambda { |val_arr| issn_parse(val_arr[0])}
    
    # Strip line breaks from Title, Abstract, Affiliation, Publication
    @value_translators[:ti] = lambda { |val_arr| strip_line_breaks(val_arr[0])}
    @value_translators[:ab] = lambda { |val_arr| strip_line_breaks(val_arr[0])}
    @value_translators[:ad] = lambda { |val_arr| strip_line_breaks(val_arr[0])}
    @value_translators[:jt] = lambda { |val_arr| strip_line_breaks(val_arr[0])}
    @value_translators[:ta] = lambda { |val_arr| strip_line_breaks(val_arr[0])}

    #Mapping of Medline Types => valid BibApp Types
    @type_mapping = {                         
      "abst"                              => "Abstract",  # Abstract
      "advs"                              => "Generic",  # Audiovisual material
      "art"                               => "ArtWork", # Art work
      "bill"                              => "BillResolution", # Bill/Resolution
      "book"                              => "BookWhole",  # Book, whole
      "case"                              => "Case", # Case
      "chap"                              => "BookSection",  # Book chapter
      "comp"                              => "ComputerProgram", # Computer program
      "conf"                              => "ConferenceProceeding",  # Conference proceeding
      "ctlg"                              => "Generic",  # Catalog
      "data"                              => "Generic",  # Data file
      "elec"                              => "ElectronicCitation", # Electronic citation
      "gen"                               => "Generic",  # Generic
      "hear"                              => "Hearing", # Hearing
      "icomm"                             => "InternetCommunication", # Internet communication
      "inpr"                              => "InPress", # In Press
      "jfull"                             => "JournalArticle",  # Journal (full)
      "jour"                              => "JournalArticle",  # Journal
      "map"                               => "Map", # Map
      "mgzn"                              => "Magazine", # Magazine
      "mpct"                              => "MotionPicture", # Motion picture
      "music"                             => "MusicScore", # Music score
      "news"                              => "Newspaper", # Newspaper
      "pamp"                              => "Generic",  # Pamphlet
      "pat"                               => "Patent",  # Patent
      "pcomm"                             => "PersonalCommunication", # Personal communication
      "rprt"                              => "Report",  # Report
      "ser"                               => "JournalArticle",  # Serial (Book, Monograph)
      "slide"                             => "Generic",  # Slide
      "sound"                             => "SoundRecording", # Sound recording
      "stat"                              => "Statute", # Statute
      "thes"                              => "DissertationThesis", # Thesis/Dissertation
      "unbill"                            => "UnenactedBillResolution", # Unenacted bill/resolution
      "unpb"                              => "UnpublishedWork", # Unpublished work
      "video"                             => "VideoRecording", # Video recording
      "abbreviations"  => "Generic",
      "abstracts"  => "Abstract",
      "academic dissertations"  => "DissertationThesis",
      "account books"  => "Generic",
      "addresses"  => "Generic",
      "advertisements"  => "Generic",
      "almanacs"  => "Generic",
      "anecdotes"  => "Generic",
      "animation"  => "Generic",
      "annual reports"  => "Report",
      "aphorisms and proverbs"  => "Generic",
      "architectural drawings"  => "Generic",
      "atlases"  => "BookEdited",
      "bibliography"  => "Generic",
      "biobibliography"  => "Generic",
      "biography"  => "BookWhole",
      "book illustrations"  => "Generic",
      "book reviews"  => "JournalArticle",
      "bookplates"  => "Generic",
      "broadsides"  => "Generic",
      "caricatures"  => "Generic",
      "cartoons"  => "Generic",
      "case reports"  => "Report",
      "catalogs"  => "Generic",
      "charts"  => "Generic",
      "chronology"  => "Generic",
      "classical article"  => "Generic",
      "clinical conference"  => "Generic",
      "clinical trial"  => "Generic",
      "clinical trial, phase i"  => "Generic",
      "clinical trial, phase ii"  => "Generic",
      "clinical trial, phase iii"  => "Generic",
      "clinical trial, phase iv"  => "Generic",
      "collected correspondence"  => "Generic",
      "collected works"  => "Generic",
      "collections"  => "Generic",
      "comment"  => "Generic",
      "comparative study"  => "Generic",
      "congresses"  => "Generic",
      "consensus development conference"  => "Generic",
      "consensus development conference, NIH"  => "Generic",
      "controlled clinical trial"  => "Generic",
      "corrected and republished article"  => "Generic",
      "database"  => "Generic",
      "diaries"  => "Generic",
      "dictionary"  => "Generic",
      "directory"  => "Generic",
      "documentaries and factual films"  => "Generic",
      "drawings"  => "Generic",
      "duplicate publication"  => "Generic",
      "editorial"  => "Generic",
      "encyclopedias"  => "Generic",
      "english abstract"  => "Generic",
      "ephemera"  => "Generic",
      "essays"  => "Generic",
      "eulogies"  => "Generic",
      "evaluation studies"  => "Generic",
      "examination questions"  => "Generic",
      "exhibitions"  => "Generic",
      "festschrift"  => "Generic",
      "fictional works"  => "Generic",
      "forms"  => "Generic",
      "funeral sermons"  => "Generic",
      "government publications"  => "Generic",
      "guidebooks"  => "Generic",
      "guideline"  => "Generic",
      "handbooks"  => "Generic",
      "herbals"  => "Generic",
      "historical article"  => "Generic",
      "humor"  => "Generic",
      "in vitro"  => "Generic",
      "indexes"  => "Generic",
      "instruction"  => "Generic",
      "interactive tutorial"  => "Generic",
      "interview"  => "Generic",
      "introductory journal article"  => "Generic",
      "journal article"  => "JournalArticle",
      "juvenile literature"  => "Generic",
      "laboratory manuals"  => "Generic",
      "lecture notes"  => "Generic",
      "lectures"  => "Generic",
      "legal cases"  => "CourtCaseDecision",
      "legislation"  => "LawStatutes",
      "letter"  => "Generic",
      "manuscripts"  => "Generic",
      "maps"  => "Map",
      "meeting abstracts"  => "Abstract",
      "meta-analysis"  => "Generic",
      "monograph"  => "Monograph",
      "multicenter study"  => "Generic",
      "news"  => "Generic",
      "newspaper article"  => "NewspaperArticle",
      "nurses' instruction"  => "Generic",
      "outlines"  => "Generic",
      "overall"  => "Generic",
      "patents"  => "Patent",
      "patient education handout"  => "Generic",
      "periodical index"  => "Generic",
      "periodicals"  => "Generic",
      "personal narratives"  => "Generic",
      "pharmacopoeias"  => "Generic",
      "phrases"  => "Generic",
      "pictorial works"  => "Generic",
      "popular works"  => "Generic",
      "portraits"  => "Generic",
      "posters"  => "Generic",
      "practice guideline"  => "Generic",
      "price lists"  => "Generic",
      "problems and exercises"  => "Generic",
      "programmed instruction"  => "Generic",
      "programs"  => "Generic",
      "prospectuses"  => "Generic",
      "publication components"  => "Generic",
      "publication formats"  => "Generic",
      "published erratum"  => "Generic",
      "randomized controlled trial"  => "Generic",
      "research support, n.i.h., extramural"  => "JournalArticle",
      "research support, n.i.h., intramural"  => "JournalArticle",
      "research support, non-u.s. gov't"  => "JournalArticle",
      "research support, u.s. gov't, non-p.h.s."  => "JournalArticle",
      "research support, u.s. gov't, p.h.s."  => "JournalArticle",
      "resource guides"  => "Generic",
      "retracted publication"  => "Generic",
      "retraction of publication"  => "Generic",
      "review"  => "Generic",
      "scientific integrity review"  => "Generic",
      "sermons"  => "Generic",
      "statistics"  => "Generic",
      "study characteristics"  => "Generic",
      "support of research"  => "Generic",
      "tables"  => "Generic",
      "technical report"  => "Generic",
      "terminology"  => "Generic",
      "textbooks"  => "Generic",
      "twin study"  => "Generic",
      "unedited footage"  => "Generic",
      "union lists"  => "Generic",
      "unpublished works"  => "Generic",
      "validation studies"  => "Generic"
    }
  end
  
  def publication_date_parse(publication_date)
    date = Hash.new
    
    date[:publication_date] = parse_date(publication_date)
    
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