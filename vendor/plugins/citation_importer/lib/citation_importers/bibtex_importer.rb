class BibtexImporter < CitationImporter
  

  def self.import_formats
    [:bibtex]
  end

  def generate_attribute_hash(parsed_citation)
    r_hash = Hash.new
    return false if !self.class.import_formats.include?(parsed_citation.citation_type)
    props = parsed_citation.properties
    props.each do |key, values|
      r_key = @attr_map[key]
      next if r_key.nil? or @attr_translators[r_key].nil?
      r_val = @attr_translators[key].call(values)
      if r_val.respond_to? :keys
        r_val.each do |s_key, s_val|
          r_hash[s_key] = s_val
        end
      else
        r_hash[r_key] = r_val
      end
    end
    return r_hash
  end
  
  def initialize
    @attr_map = {
       :type          => :reftype_id,
       :title         => :title_primary,
       :author        => :authors,
       :year          => :pub_year,
       :booktitle     => :title_secondary,
       :pages         => :start_page,
       :key           => :identifying_phrase,
       :journal       => :periodical_full,
       :volume        => :volume,
       :number        => :issue,
       :note          => :notes,
       :publisher     => :publisher,
       :series        => :title_secondary,
       :edition       => :edition,
       :address       => :place_of_publication,
       :organization  => :title_tertiary,
       :school        => :publisher,
       :institution   => :publisher
       
    }
  
    @attr_translators = Hash.new(lambda { |val_arr| val_arr.join("|") })
    @attr_translators[:type] = lambda { |val_arr| @reftype_map[val_arr[0].downcase]}
    @attr_translators[:pages] = lambda { |val_arr| page_range_parse(val_arr[0])}

    @reftype_map = {
      "article"       => 1,   # Journal Article
      "book"          => 3,   # Book, Whole
      "booklet"       => 0,   # Generic
      "conference"    => 5,   # Conference Proceeding
      "inbook"        => 4,   # Book, Section
      "incollection"  => 4,   # Book, Section
      "inproceedings" => 5,   # Conference Proceeding
      "manual"        => 0,   # Generic
      "mastersthesis" => 9,   # Dissertation/Thesis
      "misc"          => 0,   # Generic
      "phdthesis"     => 9,   # Dissertation/Thesis
      "proceedings"   => 5,   # Conference Proceeding
      "techreport"    => 7,   # Report
      "unpublished"   => 24,  # Unpublished Material
    }
  end
  
  def page_range_parse(range)
    page_range = Hash.new
    pages = range.split("-")
    page_range[:start_page] = pages[0]
    page_range[:end_page]   = pages[1]
    return page_range
  end
  
end