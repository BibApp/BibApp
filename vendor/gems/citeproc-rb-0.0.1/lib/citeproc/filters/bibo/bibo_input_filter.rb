#  == Synopsis
#
#  Resolves CSL variables to the underlying Bibliontology model.
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
  class BiboInputFilter < Citeproc::InputFilter
    
    # Loads the citations from +source+, based on the content_type passed in the +params+.
    def load_citations(source, params)
      io = source.read
      content_type = params[:content_type]
      
      # Try loading the citations as either a YAML file
      case content_type.downcase
      when "yaml"
        require 'yaml'
        results = YAML.load(io)
        if results.kind_of? Hash
          @citations = results
        else
          print_type_error(results, "YAML should contain either a Document or an Array of documents.")
        end
      when "json"
        require 'json'
        results = JSON.parse(io)
      when "rdf"
        # Use Redland here...
      else
        raise RuntimeError.new("Unsupported content-type: " + content_type.inspect + ". Must be either YAML or JSON.")
      end
    end


    
    def extract_contributor(role)
      @current_citation.each_contribution do |contrib|
        yield contrib.contributor if role == contrib.role.name
      end
    end
    
    
    
    # Tests the document class, and returns the corresponding CSL type
    def resolve_type
      case @current_citation.class
      when Bibo::Book
        'book'
        # Need to add more 
      else
        'article' # Reasonable default?
      end
    end
    
    def extract_date(variable)
      case variable
      when "issued"
        @current_citation.date
      when "event" # Kludgy way of handling event - treat as presentation
        @current_citation.presented_at.time.start if @current_citation.presented_at and @current_citation.presented_at.time
      when "accessed"
        @current_citation.accessed
      when "container"
        @current_citation.belongs_to.date if @current_citation.belongs_to
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
      when 'author', 'editor', 'translator'
        @current_citation.contributions.each do |contrib|
          if contrib.role == variable
            return contrib.contributor
          end
        end
    
      ## the primary title for the cited item
      when 'title'
        @current_citation.title

      ## the secondary title for the cited item; for a book chapter, this 
      ## would be a book title, for an article the journal title, etc.
      when 'container-title'
        @current_citation.belongs_to.title if @current_citation.belongs_to

      ## the tertiary title for the cited item; for example, a series title
      when 'collection-title'
        @current_citation.belongs_to.belongs_to.title if @current_citation.belongs_to and @current_citation.belongs_to.belongs_to

      ## title of a related original version; often useful in cases of translation
      when "original-title"
        @current_citation.translation_of.title if @current_citation.translation_of
        @current_citation.review_of.title if @current_citation.review_of
        @current_citation.transcript_of.title if @current_citation.transcript_of

      ## the name of the publisher
      when "publisher"
        @current_citation.publisher

      ## the location of the publisher
      when "publisher-place"
        @current_citation.place.name if @current_citation.place

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
        @current_citation.presented_at.name if @current_citation.presented_at

      ## the location or place for the related event
      when "event-place"
        @current_citation.presented_at.place.name if @current_citation.presented_at and @current_citation.presented_at.place

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
      end
    end
  end
end
