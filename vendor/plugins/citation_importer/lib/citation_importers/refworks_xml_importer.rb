#
# Refworks XML format importer for BibApp
# 
# Initializes attribute mapping & value translators,
# used to generate a valid BibApp attribute Hash.
# 
# For the actual processing & attribute hash creation,
# see the BaseImporter.
#
class RefworksXmlImporter < BaseImporter

  attr_reader :type_mapping
  
  class << self
    def import_formats
      [:refworks_xml]
    end
  end
  
  #Initialize our Refworks XML importer
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
      :url => :links,
      :original_data => :original_data
    }
  
    #Initialize our Value Translators (which will translate values from normal RefWorks XML)
    @value_translators = Hash.new(lambda { |val_arr| Array(val_arr) })

    # Map NameString and CitationNameStringType
    # example {:name => "Larson, EW", :type=> "Author"}
    @value_translators[:author_primary] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Author"}}}
    @value_translators[:author_secondary] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Editor"}}}
    
    # Map publication types (see @type_mapping)
    @value_translators[:ref_type] = lambda { |val_arr| Array(@type_mapping[val_arr[0]]) }
    
    # Convert publication year into a date
    @value_translators[:pub_year] = lambda { |val_arr| val_arr.collect!{|n| Date.new(n.to_i).to_s}}
    
    #Mapping of RefWorks XML Publication Types => valid BibApp Types
    @type_mapping = {
      "Abstract" => "Abstract",
      "Artwork" =>	"Artwork",
      "Bills/Resolutions" => "BillsResolutions",
      "Book, Edited" => "BookEdited",
      "Book, Section" => "BookSection",
      "Book, Whole" => "BookWhole",
      "Case/Court Decisions" => "CaseCourtDecisions",
      "Computer Program" => "ComputerProgram",
      "Conference Proceedings" => "ConferenceProceeding",
      "Dissertation/Thesis" => "DissertationThesis",
      "Dissertation/Thesis, Unpublished" => "DissertationThesis",
      "Generic" => "Generic",
      "Grant" => "Grant",
      "Hearing" => "Hearing",
      "Journal Article" => "JournalArticle",
      "Journal, Electronic" => "JournalArticle",
      "Laws/Statutes" => "LawsStatutes",
      "Magazine Article" => "MagazineArticle",
      "Map" => "Map",
      "Monograph" => "Monograph",
      "Motion Picture" => "MotionPicture",
      "Music Score" => "MusicScore",
      "Newspaper Article" => "NewspaperArticle",
      "Online Discussion Forum/Blogs" => "OnlineDiscussionForum",
      "Patent" => "Patent",
      "Personal Communication" => "PersonalCommunication",
      "Report" => "Report",
      "Sound Recording" => "SoundRecording",
      "Unpublished Material" => "UnpublishedMaterial",
      "Video/DVD" => "Video",
      "Web Page" => "WebPage"
    }
  end
end