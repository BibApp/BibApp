#  == Synopsis
#
#  Resolves CSL variables to a simple Citation model.
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

module CSL
  class CslInputFilter < Citeproc::InputFilter
    
    
    # Loads the citations from +source+, based on the content_type passed in the +params+.
    def load_citations(source, params)
      io = source.read
      content_type = params[:content_type]

      # Load the citations from the specified content type
      case content_type.downcase
      when "yaml"
        require 'yaml'
        results = YAML.load(io)
      when "json"
        require 'json'
        results = JSON.parse(io)
      else
        raise RuntimeError.new("Unsupported content-type: " + content_type.inspect + ". Must be either YAML or JSON.")
      end

      results.each do |key, value|
        citation = load_citation_from_hash(value)
        @citations[key] = citation
      end if results
    end
    
    
    
    # Loads an individual citation from the +hash+ object
    def load_citation_from_hash(hash)
      citation = Citation.new
      # Much easier, but requires active_support (sudo gem install active_support --include-dependencies)
      # Overkill for just this method?
      if require "active_support"
        hash.each do |k, v|
          citation.send("#{k.underscore}=", v)
        end
      # Long hand... potentially incomplete
      else
        citation.type = hash[:type.to_s]
        citation.title = hash[:title.to_s]
        citation.container_title = hash[:containerTitle.to_s]
        citation.collection_title = hash[:collectionTitle.to_s]
        citation.date_issued = hash[:dateIssued.to_s]
        citation.date_accessed = hash[:dateAccessed.to_s]
        citation.publisher = hash[:publisher.to_s]
        citation.publisher_place = hash[:publisherPlace.to_s]
        citation.issue = hash[:issue.to_s]
        citation.url = hash[:url.to_s]
        citation.pages = hash[:pages.to_s]
        citation.authors = hash[:authors.to_s]
        citation.editors = hash[:editors.to_s]
      end
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
      @current_citation.type
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
      if date
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
        @current_citation.authors
    
      when 'editor'
        @current_citation.editors
    
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
