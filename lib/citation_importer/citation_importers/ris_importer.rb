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
      :a1 => :work_name_strings,
      :a2 => :work_name_strings,
#     :a3 => @TODO - Author Series
      :ab => :abstract,
      :au => :work_name_strings,
      :ad => :affiliation,
#     :av => @TODO - Availability
      :bn => :issn_isbn, # Non-RIS tag?
      :bt => :title_secondary,
      :c2 => :links, # Mapped to PMCID by Zotero, https://github.com/aurimasv/translators/wiki/RIS-Tag-Map.
      :cp => :issue,
      :ct => :title_primary,
      :cy => :publication_place,
      :do => :links,
      :ed => :work_name_strings,
      :ep => :end_page,
#      :id => :identifier, # Usually a local identifier which becomes meaningless in a multi-user system. # No longer appears in the RIS format spec, http://www.refman.com/support/risformat_intro.asp
      :is => :issue,
      :j1 => :publication_j1, # No longer appears in the RIS format spec, http://www.refman.com/support/risformat_intro.asp
      :j2 => :publication_j2, # Alternate Title for Journals, Abbreviated Title for Books
      :ja => :publication_ja, # No longer appears in the RIS format spec, http://www.refman.com/support/risformat_intro.asp
      :jf => :publication_jf, # No longer appears in the RIS format spec, http://www.refman.com/support/risformat_intro.asp
      :jo => :publication_jo, # No longer appears in the RIS format spec, http://www.refman.com/support/risformat_intro.asp
      :kw => :keywords,
      :l1 => :links, # L1 is now for file attachments, according to spec. Not sure how this is applied in practice.
      :l2 => :links, # L2 no longer appears in RIS format spec, http://www.refman.com/support/risformat_intro.asp
#      :l3 => @TODO - Related Records
#      :l4 => @TODO - Images
      :m1 => :notes,
      :m2 => :notes,
      :m3 => :notes,
      :n1 => :notes,
      :n2 => :abstract,
      :pb => :publisher,
      :py => :publication_date,
#     :rp => @TODO - Reprint Status
      :sn => :issn_isbn,
      :sp => :start_page,
      :t1 => :title_primary,
      :t2 => :publication_t2, # Title of the incorporating work, e.g. if :ti is article, :t2 is journal title. If :ti is book section, :t2 is books. If :ti is book, :t2 is series title.
      :t3 => :title_tertiary,
      :ti => :title_primary, # Title of the work being described
      :ty => :klass,
      :u1 => :user_definable,
      :u2 => :user_definable,
      :u3 => :user_definable,
      :u4 => :user_definable,
      :u5 => :user_definable,
      :ur => :links,
      :vl => :volume,
      :y1 => :publication_date,
      :y2 => :publication_date
    }

    #the first of these that matches will eventually become the publication field and
    #the rest will be discarded
    @publication_priority = [:jf, :jo, :ja, :j1, :t2, :j2].collect {|suffix| :"publication_#{suffix}"}

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
    @value_translators[:y2] = lambda { |val_arr| publication_date_parse(val_arr[0].to_s)}

    #squish fields as needed
    @value_translators[:n2] = lambda {|val_arr| strip_line_breaks(val_arr[0].to_s)}

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
    true
  end

  def callbacks(hash)
    prioritize(hash, :publication, *(@publication_priority))
    make_names_unique(hash)
    hash
  end

end
