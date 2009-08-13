#
# Refworks XML (deprecated) format importer for BibApp
# 
# (Since the old version of RefWorks XML format was 
#  deprecated by Refworks, it's recommended to use
#  the newer RefworksXmlImporter)
# 
# Initializes attribute mapping & value translators,
# used to generate a valid BibApp attribute Hash.
# 
# For the actual processing & attribute hash creation,
# see the BaseImporter.
#
class RefworksDeprecatedXmlImporter < BaseImporter

  attr_reader :type_mapping
  
  class << self
    def import_formats
      [:refworks_deprecated_xml]
    end
  end
  
  #Initialize our Refworks XML (Deprecated) importer
  def initialize
    #Mapping of Refworks XML Attributes => BibApp Attributes
    @attribute_mapping = {
      :ref_type => :klass,
      :author_primary => :work_name_strings,
      :author_secondary => :work_name_strings, #RefWorks loads Editors here
      :title_primary => :title_primary,
      :title_secondary => :title_secondary,
      :title_tertiary => :publication, # RefWorks loads Conference Proceeding publication data here
      :keyword => :keywords,
      :pub_year => :publication_date,
      :periodical_full => :publication,
      :periodical_abbrev => :publication,
      :volume => :volume,
      :issue => :issue,
      :start_page => :start_page,
      :other_pages => :end_page, #RefWorks loads end page here
      :publisher => :publisher,
      :place_of_publication => :publication_place,
      :issn_isbn => :issn_isbn,
      :author_address_affiliations => :affiliation,
      :language => :language,
      :links => :links,
      :doi => :links,
      :abstract => :abstract,
      :notes => :notes,
      :user_2 => :keywords,
      :data_source => :source,
      :identifying_phrase => :external_id,
      :url => :links
    }
  
    #Initialize our Value Translators (which will translate values from normal RefWorks XML)
    @value_translators = Hash.new(lambda { |val_arr| Array(val_arr) })

    # Map NameString and CitationNameStringType
    # example {:name => "Larson, EW", :type=> "Author"}
    @value_translators[:author_primary] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Author"}}}
    @value_translators[:author_secondary] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Editor"}}}
    
    # Map publication types (see @type_mapping)
    @value_translators[:ref_type] = lambda { |val_arr| Array(@type_mapping[val_arr[0].to_s]) }
    # Convert publication year into a date
    @value_translators[:pub_year] = lambda { |val_arr| publication_date_parse(val_arr[0].to_s)}
    
    #Mapping of RefWorks XML Publication Types => valid BibApp Types
    @type_mapping = {
      "0"  => "Generic",
      "1"  => "JournalArticle",
      "2"  => "Abstract",
      "3"  => "BookWhole",
      "4"  => "BookSection",
      "5"  => "ConferenceProceeding",
      "6"  => "Patent",
      "7"  => "Report",
      "8"  => "Monograph",
      "9"  => "DissertationThesis",
      "10" => "WebPage",
      "11" => "JournalArticle",
      "12" => "NewspaperArticle",
      "13" => "BookEdited",
      "14" => "DissertationThesis",
      "15" =>	"Artwork",
      "16" => "Video",
      "17" => "MagazineArticle",
      "18" => "Map",
      "19" => "MotionPicture",
      "20" => "MusicScore",
      "21" => "SoundRecording",
      "22" => "PersonalCommunication",
      "23" => "Grant",
      "24" => "UnpublishedMaterial",
      "25" => "OnlineDiscussionForum",
      "26" => "CaseCourtDecisions",
      "27" => "Hearing",
      "28" => "LawsStatutes",
      "29" => "BillsResolutions",
      "30" => "ComputerProgram"
    }
  end
  
  def import_callbacks?
    false
  end
end