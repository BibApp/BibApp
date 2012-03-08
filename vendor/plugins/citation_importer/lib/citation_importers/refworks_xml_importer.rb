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
      :periodical_full => :periodical_full,
      :periodical_abbrev => :periodical_abbrev,
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

    @publication_priority = [:full, :abbrev].collect {|suffix| :"periodical_#{suffix}"}

    #Initialize our Value Translators (which will translate values from normal RefWorks XML)
    @value_translators = Hash.new(lambda { |val_arr| Array(val_arr) })

    # Map NameString and CitationNameStringType
    # example {:name => "Larson, EW", :type=> "Author"}
    @value_translators[:author_primary] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Author"}}}
    @value_translators[:author_secondary] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Editor"}}}

    # Map publication types (see @type_mapping)
    @value_translators[:ref_type] = lambda { |val_arr| Array(@type_mapping[val_arr[0].to_s]) }

    # Parse publication dates
    @value_translators[:pub_date] = lambda { |val_arr| publication_date_parse(val_arr[0].to_s)}
    @value_translators[:pub_year] = lambda { |val_arr| publication_date_parse(val_arr[0].to_s)}

    #Mapping of RefWorks XML Publication Types => valid BibApp Types
    @type_mapping = {
      "Abstract" => "Generic",
      "Artwork" =>	"Artwork",
      "Bills/Resolutions" => "Generic",
      "Book, Edited" => "BookWhole",
      "Book, Section" => "BookSection",
      "Book, Whole" => "BookWhole",
      "Case/Court Decisions" => "Generic",
      "Computer Program" => "Generic",
      "Conference Proceedings" => "ConferencePaper",
      "Dissertation/Thesis" => "DissertationThesis",
      "Dissertation/Thesis, Unpublished" => "DissertationThesis",
      "Generic" => "Generic",
      "Grant" => "Grant",
      "Hearing" => "Generic",
      "Journal Article" => "JournalArticle",
      "Journal, Electronic" => "JournalArticle",
      "Laws/Statutes" => "Generic",
      "Magazine Article" => "Generic",
      "Map" => "Generic",
      "Monograph" => "Monograph",
      "Motion Picture" => "RecordingMovingImage",
      "Music Score" => "RecordingSound",
      "Newspaper Article" => "Generic",
      "Online Discussion Forum/Blogs" => "Generic",
      "Patent" => "Patent",
      "Personal Communication" => "Generic",
      "Report" => "Report",
      "Sound Recording" => "RecordingSound",
      "Unpublished Material" => "Generic",
      "Video/DVD" => "RecordingMovingImage",
      "Web Page" => "WebPage"
    }
  end

  def import_callbacks?
    true
  end

  def callbacks(hash)
    prioritize(hash, :publication, *(@publication_priority))
    hash
  end

end