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
       :ty => :reftype_id,
       :t1 => :title_primary,
       :ti => :title_primary,
       :bt => :title_secondary,
       :t3 => :title_tertiary,
       :a1 => :authors,
       :ad => :affiliations,
       :jf => :periodical_full,
       :ja => :periodical_abbrev,
       :jo => :periodical_full,
       :pb => :publisher,
       :kw => :keywords,
       :u1 => :user_1,
       :u2 => :user_2,
       :n2 => :abstract,
       :y1 => :pub_year,
       :py => :pub_year,
       :sp => :start_page,
       :ep => :end_page,
       :vl => :volume,
       :is => :issue,
       :sn => :issn_isbn,
       :cy => :place_of_publication,
       :bn => :issn_isbn,
       :n1 => :notes,
       :m1 => :notes,
       :l2 => :links
    }
  
    @attr_translators = Hash.new(lambda { |val_arr| val_arr.join("|") })
    @attr_translators[:ty] = lambda { |val_arr| @reftype_map[val_arr[0]] }
    @attr_translators[:y1] = lambda { |val_arr| val_arr[0].to_i }
    @attr_translators[:py] = lambda { |val_arr| val_arr[0].to_i }
  
    @reftype_map = {
       "ABST"  => 2,  # Abstract
       "ADVS"  => 0,  # Audiovisual material
       "ART"   => 15, # Art work
       "BILL"  => 29, # Bill/Resolution
       "BOOK"  => 3,  # Book, whole
       "CASE"  => 26, # Case
       "CHAP"  => 4,  # Book chapter
       "COMP"  => 30, # Computer program
       "CONF"  => 5,  # Conference proceeding
       "CTLG"  => 0,  # Catalog
       "DATA"  => 0,  # Data file
       "ELEC"  => 11, # Electronic citation
       "GEN"   => 0,  # Generic
       "HEAR"  => 27, # Hearing
       "ICOMM" => 22, # Internet communication
       "INPR"  => 24, # In Press
       "JFULL" => 1,  # Journal (full)
       "JOUR"  => 1,  # Journal
       "MAP"   => 18, # Map
       "MGZN"  => 17, # Magazine
       "MPCT"  => 19, # Motion picture
       "MUSIC" => 20, # Music score
       "NEWS"  => 12, # Newspaper
       "PAMP"  => 0,  # Pamphlet
       "PAT"   => 6,  # Patent
       "PCOMM" => 22, # Personal communication
       "RPRT"  => 7,  # Report
       "SER"   => 1,  # Serial (Book, Monograph)
       "SLIDE" => 0,  # Slide
       "SOUND" => 21, # Sound recording
       "STAT"  => 28, # Statute
       "THES"  => 14, # Thesis/Dissertation
       "UNBILL"=> 29, # Unenacted bill/resolution
       "UNPB"  => 24, # Unpublished work
       "VIDEO" => 16 # Video recording
    }
  end
end