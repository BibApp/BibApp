#  == Synopsis
#
# Models the Bibliographic Ontology in Ruby.
# See http://wiki.bibliontology.com/index.php/Ontology_Working_Draft for further details.
# 
# Several liberties have been taken, based on Ruby idioms and conventions.
# In particular, in several cases classes have been modelled as modules, to permit
# multiple inheritance which is a feature of RDF/OWL. This is less than satisfactory
# in the case of the Collection module especially, and there may be a preferable means
# of handling this use case.
# 
# Comments and order have been kept as close to the Bibliographic Ontology as possible,
# for easy reference and maintenance.
#
#  == Author
#
#  Liam Magee
#
#  == Copyright
#
#  Copyright (c) 2007, Liam Magee.
#  Licensed under the same terms as Ruby - see http://www.ruby-lang.org/en/LICENSE.txt.
#
 
module Bibo
  # ---------- Modules -----------

  # ---------------------------------------
  # -------- External Ontologies ----------
  # ---------------------------------------

  # Note: these classes and properties, from other ontologies, are re-used 
  # and preffered by The Bibliographic Ontology. The Bibliographic Ontology 
  # is extended by their use, but is not limited to them.


  # ---------- General (RDFS) Classes -------------
  module Generic 
    class Resource
      attr_accessor :short_title
      # -------- DCTERMS ----------
      # Note: unchecked for the moment - not clear how this would be done
      attr_accessor :date, :format, :identifier, :language, :rights, :subject, :title, :part_of, :publisher 
      
      def initialize(title = nil)
	@title = title
      end
    end

  end
  
  # Includes the Generic (RDFS) module
  include Generic
  
  
  # --------- wgs84_pos -------------
  # 
  # See http://www.w3.org/2003/01/geo/wgs84_pos
  #
  module Wgs84_pos
    class SpatialThing
      attr_accessor :name # NB: Not from bibliontology

      # Probably should be some datatype? 
      attr_accessor :latitude, :longitude, :altitude 
      attr_accessor :based_near
      
      def initialize(latitude, longitude, altitude)
        @latitude = latitude
        @longitude = longitude
        @altitude = altitude
      end
      
      def initialize(name = nil)
        @name = name
      end
      
      def based_near=(value)
        if !value.kind_of?(SpatialThing)
            raise(ArgumentError, "based_near #{value} isn't an SpatialThing")
        end
        @based_near = value
      end    
    end
    
    # For completeness' sake
    class Point
      
    end
  end
  
  # Includes the Wgs84_pos module
  include Wgs84_pos
  
  
  # --------- Time -------------
  # 
  # See http://www.w3.org/2006/time
  # 
  # Modelled very simply - Interval has a a start and end Time, Instant only one time
  #
  module Times
    class TemporalEntity
      
    end    
    
    class Interval < TemporalEntity
      attr_accessor :start, :end
      
      def initialize(s, e)
        @start = s
        @end = e
      end
      
      def start=(value)
        if !value.kind_of?(Time)
            raise(ArgumentError, "start time #{value} isn't a Time")
        end
        @start = value
      end     
      
      def end=(value)
        if !value.kind_of?(Time)
            raise(ArgumentError, "end time #{value} isn't a Time")
        end
        @end = value
      end     
    end
    
    class Instant < TemporalEntity
      attr_accessor :point_in_time
      
      def initialize(point_in_time)
        @point_in_time = point_in_time
      end
      
      def point_in_time=(value)
        if !value.kind_of?(Time)
            raise(ArgumentError, "point in time #{value} isn't a Time")
        end
        @point_in_time = value
      end     
      
    end
  end
  
  # Includes the time module
  include Times
  
  
  # --------- FOAF -------------
  #
  # See http://xmlns.com/foaf/spec/
  #
  module FOAF
    
    class Agent
      # Defined by FOAF (just the basics - see http://xmlns.com/foaf/spec/)
      attr_accessor :name, :nick, :title, :homepage, :mbox, :mbox_sha1sum, :img, :depiction
      # Not sure what to do with these? :surname, :family_name, :givenname, :firstName
      # Defined by Bibliographic Ontology
      attr_accessor :given_name, :family_name, :prefix_name, :suffix_name 
    end

    class Person < Agent

    end

    class Organisation < Agent

    end
  end

  # Includes the FOAF module
  include FOAF



  # ------- Event ---------
  # 
  # See http://purl.org/NET/c4dm/event.owl#
  #
  module Events
    class Event
      attr_accessor :name # NB: Not from bibliontology
      attr_accessor :agent, :product, :sub_event, :time, :place

      def agent=(value)
        if !value.kind_of?(FOAF::Agent)
            raise(ArgumentError, "agent #{value} isn't an Agent")
        end
        @agent = value
      end    

      def sub_event=(value)
        if !value.kind_of?(Event)
            raise(ArgumentError, "sub-event #{value} isn't an Event")
        end
        @sub_event = value
      end    

      def time=(value)
        if !value.kind_of?(Times::TemporalEntity)
            raise(ArgumentError, "time #{value} isn't an TemporalEntity")
        end
        @time = value
      end     

      def place=(value)
        if !value.kind_of?(Wgs84_pos::SpatialThing)
            raise(ArgumentError, "place #{value} isn't an SpatialThing")
        end
        @place = value
      end     
    end
  end

  # Includes the Event module
  include Events

    
  # Note: Pseudo-classes, designed as modules to permit Ruby mixins
  
  module PersonalCommunication
    
  end  
  
  module Collection
    attr_accessor :documents
    # ------ Document Identifier Type -----------
    attr_accessor :identifier, :isbn10, :isbn13, :asin, :coden, :uri, :doi
    attr_accessor :oclcnum, :issn, :eissn, :sici, :lccn, :eanucc13, :upc, :gtin14
    
    def initialize
      @documents = []
    end
    
    def add_document(doc)
      @documents << doc
    end
  end  

  
  
  
  
  # ---------- Classes -----------

  
  # ---------- Document -----------
  
  class Document < Resource
    # How to represent rdfs:Resource for review_of and transcript_of relations?
    # ---------- Relations --------------
    attr_accessor :translation_of, :review_of, :transcript_of, :content, :presented_at
    # --------- numbers ----------------
    attr_accessor :locator, :page_start, :page_end, :pages, :volume, :issue, :number
    # ----------- status ------------------
    attr_accessor :status
    # ----------- Editions ----------------
    attr_accessor :edition, :language
    # ------ Document Identifier Type -----------
    attr_accessor :identifier, :isbn10, :isbn13, :asin, :coden, :uri, :doi, :pmid
    attr_accessor :oclcnum, :issn, :eissn, :sici, :lccn, :eanucc13, :upc, :gtin14
    # ----- contribution properties ----
    attr_accessor :contributions
    
    # NB: Not from bibliontology
    # ----- general properties ----
    attr_accessor :abstract, :keyword, :place, :version, :genre, :note, :annote # NB: Not from bibliontology
    # ----- locator properties ----
    attr_accessor :locator_type, :accessed
    # ----- collection properties ----
    attr_accessor :belongs_to           # NB: Not from bibliontology
    
    
    def initialize(title = nil)
      super(title)
      @contributions = []
    end
    
    def translation_of=(value)
      if !value.kind_of?(Document)
          raise(ArgumentError, "Translaion of #{value} isn't a Document")
      end
      @translation_of = value
    end
    
    def review_of=(value)
      if !value.kind_of?(Generic::Resource)
          raise(ArgumentError, "Review of #{value} isn't a Resource")
      end
      @review_of = value
    end
    
    def transcript_of=(value)
      if !value.kind_of?(Generic::Resource)
          raise(ArgumentError, "Transcript of #{value} isn't a Resource")
      end
      @transcript_of = value
    end
    
    def presented_at=(value)
      if !value.kind_of?(Events::Event)
          raise(ArgumentError, "Presented at #{value} isn't an Event")
      end
      @presented_at = value
    end
    
    def status=(value)
      if !value.kind_of?(DocumentStatus)
          raise(ArgumentError, "Status #{value} isn't a DocumentStatus")
      end
      @status = value
    end
    
    def add_contribution(contribution)
      if !contribution.kind_of?(Contribution)
          raise(ArgumentError, "#{contribution} isn't a Contribution")
      end
      @contributions << contribution
    end
    
    def each_contribution(&block)
      @contributions.each(&block)
    end
    
  end
  
  # Find some way to simultate MI on the Collection class here
  class CollectedDocument < Document
    
  end  
  
  class PersonalCommunicationDocument < Document
    
  end
  
  
  # ---------- Roles -------------
    
  class Role
    attr_accessor :name # NB: Not from bibliontology
    
    def initialize(name)
      @name = name
    end
  end

  class ContributionRole < Role
  end
  
  
  # ------- Thesis Degrees -------
  
  
  class ThesisDegree  
    
  end

  # Note: see individuals (artifact) file for a list of "Contribution Roles".


  # ---------- Events Types -------------

  # Note: see individuals (artifact) file for a list of "event types".


  # ---------- Status -------------
  
  class DocumentStatus
    
  end
  
  # Note: see individuals (artifact) file for a list of "status".



  # ---------- Collections -----------

  
  class Series
    # Needs to explicitly mixin Collection
    include Collection
    
  end
    
  
  class Periodical
    # Needs to explicitly mixin Collection
    include Collection
    
  end  


  # Note: all parts must be Articles
  class Journal < Periodical
    
  end  
  
  
  # Note: Can only have 1 part
  class Newspaper < Periodical
    
  end
  
  
  # Note: all parts must be Articles
  class Magazine < Periodical
    
  end

  
  class Article < Document
    
  end
  
  
  # Note: all parts must be LegalDocuments
  class CourtReporter < Periodical
    
  end  
  
  
  # Note: all parts must be Legislation
  class Code < Periodical
    
  end  
  
  
  class LegalDocument < Document
    # ---------- Relations --------------
    attr_accessor :court
    # ----------- Editions ----------------
    attr_accessor :argued
    
    def court=(value)
      if !value.kind_of?(FOAF::Organisation)
          raise(ArgumentError, "Court #{value} isn't an Organisation")
      end
      @court = value
    end
    
    def argued=(value)
      if !value.kind_of?(Time)
          raise(ArgumentError, "The argued value: #{value} isn't an instance of Time")
      end
      @court = value
    end
  end
  
  
  class Manuscript < Document
    
  end  
  
  
  class Book < Document
    
  end
  
  
  class AudioDocument < Document
    
  end

  
  class AudioVisualDocument < Document
    
  end

  
  class EditedBook < CollectedDocument
    
  end
  
  
  class Manual < Document
    
  end  

  
  class Legislation < LegalDocument
    
  end  
  
  
  class Patent < Document
    
  end

  
  class Report < Document
    
  end


  class Thesis < Document
    # ----------- degree ------------------
    attr_accessor :degree 
    
    def degree=(value)
      if !value.kind_of?(ThesisDegree)
          raise(ArgumentError, "Degree #{value} isn't an Degree")
      end
      @degree = value
    end
  end

  
  class Bill < Legislation
    
  end


  class Statute < Legislation
    
  end
  
  
  class Brief < LegalDocument
    
  end
  
  
  class Decision < LegalDocument
    
  end
  
  
  class Transcript < Document
    
  end
  
  
  # doesn't distinguish an interview from how it's manifest; e.g.
  # what about radio or tv or podcost interviews?
  class Interview < Transcript
    
  end
  
  
  class Dissertation < Thesis
    
  end


  class Letter < PersonalCommunicationDocument
    
  end
  
  
  class Proceedings 
    include Collection
    
  end
  
  
  # ---- a Contribution ----
  class Contribution
    attr_accessor :contributor, :role, :position
    
    def initialize(contributor = nil, role = nil, position = 1)
      @contributor = contributor
      @role = role
      @position = position
    end
    
    def contributor=(value)
      if !value.kind_of?(Agent)
          raise(ArgumentError, "Contributor #{value} isn't an Agent")
      end
      @contributor = value
    end

    def role=(value)
      if !value.kind_of?(Role)
          raise(ArgumentError, "Role #{value} isn't a Role")
      end
      @role = value
    end

    def position=(value)
      if !value.kind_of?(Integer)
          raise(ArgumentError, "Position #{value} isn't an Integer")
      end
      @position = value
    end
  end
  
  

  # ------------- Individuals -------------    

  # ------- Event Types ---------

  # Perhaps need a separate EventType class for these?
  CONFERENCE  = Event.new
  HEARING     = Event.new
  WORKSHOP    = Event.new
  
  
  # ------- Document Status --------  
  
  PUBLISHED     = DocumentStatus.new
  UNPUBLISHED   = DocumentStatus.new
  DRAFT         = DocumentStatus.new
  FORTHCOMING   = DocumentStatus.new
  PEER_REVIEWED     = DocumentStatus.new
  NON_PEER_REVIEWED = DocumentStatus.new
  REJECTED      = DocumentStatus.new
  ACCEPTED      = DocumentStatus.new
  
  
  # ------- Role Types --------
  
  CONTRIBUTOR   = ContributionRole.new("contributor")
  AUTHOR        = ContributionRole.new("author")
  EDITOR        = ContributionRole.new("editor")
  TRANSLATOR    = ContributionRole.new("translator")
  INTERVIEWER   = ContributionRole.new("interviewer")
  INTERVIEWEE   = ContributionRole.new("interviewee")
  RECIPIENT     = ContributionRole.new("recipient")
  
  
  # ------ Thesis Degree Type -----------
  
  MASTER        = ThesisDegree.new
  PHD           = ThesisDegree.new



  
end
  