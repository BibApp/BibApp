#
# RIS format importer for BibApp
# 
# Initializes attribute mapping & value translators,
# used to generate a valid BibApp attribute Hash.
# 
# For the actual processing & attribute hash creation,
# see the BaseImporter.
#
class RisImporter < BaseImporter
  
  attr_reader :type_mapping
  
  class << self
    def import_formats
      [:ris]
    end
  end
  
  #Initialize our RIS Importer
  def initialize
    #Mapping of RIS Attributes => BibApp Attributes
    @attribute_mapping = {
       :ty => :klass,
       :t1 => :title_primary,
       :ti => :title_primary,
       :ct => :title_primary,
       :t2 => :title_secondary,
       :bt => :title_secondary,
       :t3 => :title_tertiary,
       :a1 => :work_name_strings,
       :au => :work_name_strings,
       :a2 => :work_name_strings,
       :ed => :work_name_strings,
       :ad => :affiliation,
       :jf => :publication,
       :ja => :publication,
       :jo => :publication,
       :j1 => :publication,
       :j2 => :publication,
       :pb => :publisher,
       :kw => :keywords,
       :u2 => :keywords,
       :ab => :abstract,
       :y1 => :publication_date,
       :py => :publication_date,
       :sp => :start_page,
       :ep => :end_page,
       :vl => :volume,
       :is => :issue,
       :cp => :issue,
       :sn => :issn_isbn,
       :bn => :issn_isbn,
       :cy => :publication_place,
       :n1 => :notes,
       :n2 => :notes,
       :m1 => :notes,
       :ur => :links,
       :l1 => :links,
       :l2 => :links
    }
  
    #Initialize our Value Translators (which will translate values from normal Medline files)
    @value_translators = Hash.new(lambda { |val_arr| Array(val_arr) })

    # Map NameString and CitationNameStringType
    # example {:name => "Larson, EW", :role=> "Author"}
    @value_translators[:a1] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Author"}}}
    @value_translators[:au] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Author"}}}
    @value_translators[:a2] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Editor"}}}
    @value_translators[:ed] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Editor"}}}
    
    # Map publication types (see @type_mapping)    
    @value_translators[:ty] = lambda { |val_arr| Array(@type_mapping[val_arr[0].to_s]) }
    
    # Parse publication dates
    @value_translators[:py] = lambda { |val_arr| publication_date_parse(val_arr[0].to_s)}
    @value_translators[:y1] = lambda { |val_arr| publication_date_parse(val_arr[0].to_s)}
    
    
    #Mapping of RIS Publication Types => valid BibApp Types
    @type_mapping = {
       "ABST"  => "Generic",  # Abstract
       "ADVS"  => "Generic",  # Audiovisual material
       "ART"   => "Artwork", # Art work
       "BILL"  => "Generic", # Bill/Resolution
       "BOOK"  => "BookWhole",  # Book, whole
       "CASE"  => "Generic", # Case
       "CHAP"  => "BookSection",  # Book chapter
       "COMP"  => "Generic", # Computer program
       "CONF"  => "ConferencePaper",  # Conference paper
       "CTLG"  => "Generic",  # Catalog
       "DATA"  => "Generic",  # Data file
       "ELEC"  => "Generic", # Electronic citation
       "GEN"   => "Generic",  # Generic
       "HEAR"  => "Generic", # Hearing
       "ICOMM" => "Generic", # Internet communication
       "INPR"  => "Generic", # In Press
       "JFULL" => "JournalArticle",  # Journal (full)
       "JOUR"  => "JournalArticle",  # Journal
       "MAP"   => "Generic", # Map
       "MGZN"  => "Generic", # Magazine
       "MPCT"  => "RecordingMovingImage", # Motion picture
       "MUSIC" => "RecordingSound", # Music score
       "NEWS"  => "Generic", # Newspaper
       "PAMP"  => "Generic",  # Pamphlet
       "PAT"   => "Patent",  # Patent
       "PCOMM" => "Generic", # Personal communication
       "RPRT"  => "Report",  # Report
       "SER"   => "JournalArticle",  # Serial (Book, Monograph)
       "SLIDE" => "Generic",  # Slide
       "SOUND" => "RecordingSound", # Sound recording
       "STAT"  => "Generic", # Statute
       "THES"  => "DissertationThesis", # Thesis/Dissertation
       "UNBILL"=> "Generic", # Unenacted bill/resolution
       "UNPB"  => "Generic", # Unpublished work
       "VIDEO" => "RecordingMovingImage" # Video recording
    }
  end
  
  
  def import_callbacks?
    false
  end
  
end