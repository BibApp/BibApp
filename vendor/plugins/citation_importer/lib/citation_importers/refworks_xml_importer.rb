class RefworksXmlImporter < CitationImporter

  class << self
    def import_formats
      [:refworks_xml]
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
      r_hash["original_data"] = props["original_data"].to_s
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
  
    @attr_translators = Hash.new(lambda { |val_arr| val_arr.to_a })

    # Map NameString and CitationNameStringType
    # example {:name => "Larson, EW", :type=> "Author"}
    @attr_translators[:author_primary] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Author"}}}
    @attr_translators[:author_secondary] = lambda { |val_arr| val_arr.collect!{|n| {:name => n, :role => "Editor"}}}
    @attr_translators[:ref_type] = lambda { |val_arr| @type_map[val_arr[0]].to_a }
    @attr_translators[:pub_year] = lambda { |val_arr| val_arr.collect!{|n| Date.new(n.to_i)}}
    
    
    @type_map = {
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