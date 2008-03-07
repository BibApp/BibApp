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
      
      puts("Key: #{key}\n")
      puts("Value: #{values.inspect}\n")
      puts("Value: #{values.class}\n")
      
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
      if value.size < 2 || value.class.to_s == "String"
        r_hash[key] = value.to_s
      end
      
      if value.size >= 2 && value.class.to_s == "Array"
        r_hash[key] = value.flatten
      end
    end
    
    puts "Mapped Hash: #{r_hash.inspect}"
    return r_hash
  end
  
  def initialize
    # Todo: improve Publication and Publisher handling
    @attr_map = {
      :reftype_id => :klass,
      :name_strings => :name_strings,
      :affiliations => :affiliation,
      :title_primary => :title_primary,
      :title_secondary => :title_secondary,
      :title_tertiary => :publication, # RefWorks loads Conference Proceeding publication data here
      :keywords => :keywords,
      :year => :year,
      :periodical_full => :publication,
      :periodical_abbrev => :publication,
      :volume => :volume,
      :issue => :issue,
      :start_page => :start_page,
      :end_page => :end_page,
      :publisher => :publisher,
      :place_of_publication => :publication_place,
      :issn_isbn => :issn_isbn,
      :author_address_affiliations => :affiliation,
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
    @attr_translators[:reftype_id] = lambda { |val_arr| @type_map[val_arr[0]].to_a }
    
    @type_map = {
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
end