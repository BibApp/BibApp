#  == Synopsis
#
#  Resolves BibApp variables to the CSL simple Citation model.
#
#  == Author
#
#  Eric Larson
#
#  == Copyright
#
#  Copyright (c) 2008, Eric Larson.
#  Licensed under the same terms as Ruby - see http://www.ruby-lang.org/en/LICENSE.txt.
#

module Bibapp
  class BibappInputFilter < Citeproc::InputFilter
    
    
    # Loads the citations from +source+, based on the content_type passed in the +params+.
    def load_citations(source, params)
      io = source.to_yaml
      content_type = params[:content_type]

      results = YAML.load(io)
      results = [results].flatten
      results.each do |row|
        citation = load_citation_from_hash(row)
        @citations[row.id] = citation
      end if results
    end
    
    
    
    # Loads an individual citation from the +hash+ object
    def load_citation_from_hash(row)
      citation = SimpleCitation.new
      citation.type = row.class.name
      citation.title = row.title_primary
      citation.container_title = row.publication.blank? ? nil : row.publication.name
      citation.collection_title = row.title_tertiary
      citation.date_issued = row.year.to_s
      citation.publisher = row.publisher.name
      citation.issue = row.issue
      citation.url = row.links
      citation.pages = "#{row.start_page}-#{row.end_page}"
      citation.authors = row.authors.collect{|au| {:name => au[:name]}}
      citation.editors = row.editors.collect{|ed| {:name => ed[:name]}}
      citation
    end
    
    

    def extract_contributor(role, sort_key = nil)
      contributors = @current_citation.contributors(role, sort_key)
      contributors.each do |contrib|
        yield contrib
      end
    end
    
    # Tests the document class, and returns the corresponding CSL type
    def resolve_type
      csl_types = Hash.new
      csl_types = {
        "BookSection" => "chapter",
        "BookWhole" => "book",
        "ConferenceProceeding" => "paper-conference",
        "JournalArticle" => "article",
        "Report" => "report"
=begin        "article-magazine",
        "article-newspaper", 
        "article-journal", 
        "bill", 
        "book", 
        "chapter", 
        "entry", 
        "entry-dictionary", 
        "entry-encylopedia", 
        "figure", 
        "graphic", 
        "interview", 
        "legislation", 
        "legal_case", 
        "manuscript", 
        "map", 
        "motion_picture", 
        "musical_score", 
        "pamphlet", 
        "paper-conference", 
        "patent", 
        "post", 
        "post-weblog", 
        "personal_communication", 
        "report",
        "review",
        "review-book",
        "song",
        "speech",
        "thesis",
        "treaty",
        "webpage"
=end
      }
      return @current_citation.type = csl_types[@current_citation].class.name
    end
    
    def extract_date(variable)
      case variable
      when "issued"
        convert_date(@current_citation.date_issued)
      when "event" # Kludgy way of handling event - treat as presentation
        # @current_citation.presented_at.time.start if @current_citation.presented_at and @current_citation.presented_at.time
      when "accessed"
        convert_date(@current_citation.date_accessed)
      when "container"
        # @current_citation.belongs_to.date if @current_citation.belongs_to
      end
    end
    
    def convert_date(date)
      unless date.blank?
        date = date + "-01-01" if date.length == 4
        Date.parse(date)
      end
    end
    

    # Very simple check on the value of the locator (or, in specific cases, of other document
    # variables) to determine whether 
    # It may be be better to simply return the locator value here
    def extract_label(variable)
      singular = true
      if variable == 'page'
        singlular = (@current_citation.pages and @current_citation.pages.include?('-'))
        locator_type = variable
      else
        locator_type = @current_citation.locator_type
        case @current_citation.locator_type
        when 'issue'
          singlular = (@current_citation.issue and @current_citation.issue.include?('-'))
        when 'page'
          singlular = (@current_citation.pages and @current_citation.pages.include?('-'))
        when 'volume'
          singlular = (@current_citation.volume and @current_citation.volume.include?('-'))
        else 
          singlular = (@current_citation.locator and @current_citation.locator.include?('-'))
        end
      end
      return locator_type,  singular
    end


    
    def extract_variable(variable)
      case variable
    
      ## the primary title for the cited item
      when 'author'
        @current_citation.csl_authors
    
      when 'editor'
        @current_citation.csl_editors
    
      ## the primary title for the cited item
      when 'title'
        @current_citation.title

      ## the secondary title for the cited item; for a book chapter, this 
      ## would be a book title, for an article the journal title, etc.
      when 'container-title'
        @current_citation.container_title

      ## the tertiary title for the cited item; for example, a series title
      when 'collection-title'
        @current_citation.collection_title

      ## title of a related original version; often useful in cases of translation
      when "original-title"
        @current_citation.title

      ## the name of the publisher
      when "publisher"
        @current_citation.publisher

      ## the location of the publisher
      when "publisher-place"
        @current_citation.publisher_place

      ## the name of the archive
      when "archive"
        # @current_citation.title

      ## the location of the archive
      when "archive-place"
        # @current_citation.title

      ## the location within an archival collection (for example, box and folder)
      when "archive_location"
        # @current_citation.title

      ## the name or title of a related event such as a conference or hearing
      when "event"
        # @current_citation.presented_at.name if @current_citation.presented_at

      ## the location or place for the related event
      when "event-place"
        # @current_citation.presented_at.place.name if @current_citation.presented_at and @current_citation.presented_at.place

      ##
      when "page"
        @current_citation.pages

      ## a description to locate an item within some larger container or 
      ## collection; a volume or issue number is a kind of locator, for example.
      when "locator"
        @current_citation.locator

      ## version description
      when "version"
        @current_citation.version

      ## volume number for the container periodical
      when "volume"
        @current_citation.volume

      ## refers to the number of items in multi-volume books and such
      when "number-of-volumes"
        # ??

      ## the issue number for the container publication
      when "issue"
        @current_citation.issue

      ##
      when "chapter-number"
        @current_citation.number

      ## medium description (DVD, CD, etc.)
      when "medium"
        @current_citation.format 

      ## the (typically publication) status of an item; for example "forthcoming"
      when "status"
        @current_citation.status

      ## an edition description
      when "edition"
        @current_citation.edition

      ##
      when "genre"
        @current_citation.genre

      ## a short inline note, often used to refer to additional details of the resource
      when "note"
        @current_citation.note

      ## notes made by a reader about the content of the resource
      when "annote"
        @current_citation.annote

      ##
      when "abstract"
        @current_citation.abstract

      ##
      when "keyword"
        @current_citation.keyword

      ## a document number; useful for reports and such
      when "number"
        @current_citation.number

      ##
      when "URL"
        @current_citation.uri

      ##
      when "DOI"
        @current_citation.doi

      ##
      when "ISBN"
        @current_citation.isbn10
        
        
      else
        extract_date(variable)
      end
      
    end
  end
end
