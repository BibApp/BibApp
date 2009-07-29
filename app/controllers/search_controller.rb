class SearchController < ApplicationController

  # Find the @cart variable, used to display "add" or "remove" links for saved Works  
  before_filter :find_cart, :only => [:index, :advanced]
  
  def index
    if params[:q] || params[:fq]

      # Default SolrRuby params
      @query        = params[:q] || "" # User query
      @filter       = params[:fq] || []
      @filter_no_strip = params[:fq] || []
      @sort         = params[:sort] || "score"
      @sort         = "score" if @sort.empty?
      @page         = params[:page] || 0
      @facet_count  = params[:facet_count] || 50
      @rows         = params[:rows] || 10
      @export       = params[:export] || ""
      
      @q,@works,@facets = Index.fetch(@query, @filter, @sort, @page, @facet_count, @rows)
      
      if !@query.empty?
        @spelling_suggestions = Index.get_spelling_suggestions(@query)

        @spelling_suggestions.each do |suggestion|
          # if suggestion matches query don't suggest...
          if suggestion.downcase == @query.downcase
            @spelling_suggestions.delete(suggestion)
          end
        end
      else
        @spelling_suggestions = ""
      end
      
      #@TODO: This WILL need updating as we don't have *ALL* Work info from Solr!
      # Process:
      # 1) Get AR objects (works) from Solr results
      # 2) Init the WorkExport class
      # 3) Pass the export variable and Works to Citeproc for processing

      if @export && !@export.empty?
        works = Work.find(@works.collect{|c| c["pk_i"]}, :order => "publication_date desc")
        ce = WorkExport.new
        @works = ce.drive_csl(@export,works)
      end
      
      @people = Person.find(@facets[:people_data].collect{|p| Person.parse_solr_data(p.name)[1]})
      @people = Person.sort_by_most_recent_work(@people)
      
    else
      @q = nil
      # There's nothing to return
    end
  end
  
  def advanced
    if !params[:keywords].nil? || !params[:title].nil? || !params[:authors].nil? || !params[:issn_isbn].nil? || !params[:groups].nil?
      
      logger.debug(params.inspect)
      # Process the params and redirect to /search
      @q = Array.new
      
      logger.debug(@q.inspect)
      # Add keywords to query
      if !params[:keywords].nil? && !params[:keywords].empty?
        @q << params[:keywords]
      end

      # Add title to query
      if !params[:title].nil? && !params[:title].empty?
        @q << "title:#{params[:title]}"
      end

      # Add author to query
      if !params[:authors].nil? && !params[:authors].empty?
        @q << "authors:#{params[:authors]}"
      end
      
      # Add group to query
      if !params[:groups].nil? && !params[:groups].empty?
        @q << "groups:#{params[:groups]}"
      end
      
      # Add issn_isbn to query
      if !params[:issn_isbn].nil? && !params[:issn_isbn].empty?
        logger.debug(params[:issn_isbn].inspect)
        @q << "issn_isbn:#{params[:issn_isbn]}"
      end
      
      # Add year to query
      # Begin with SOLR/lucene's wildcard
      start_date = "*"
      end_date = "*"
      
      # If there is a start_date use it
      if !params[:start_date].nil? && !params[:start_date].empty?
        start_date = params[:start_date]
      end

      # If there is a end_date use it
      if !params[:end_date].nil? && !params[:end_date].empty?
        end_date = params[:end_date]
      end
      
      # Only if we have a non-default start_date or end_date add it to @q
      if start_date == "*" && end_date == "*"
        # Do Nothing
      else 
        @q << "year:[#{start_date} TO #{end_date}]"
      end

      logger.debug(@q.inspect)      
      # Redirect to /search with properly formated solr standard request params
      redirect_to search_path(:q => @q.join(", "))
    else
      @q = nil
      # There's nothing to return, show them the search form
    end
  end
  
  private
  
  def find_cart
    @cart = session[:cart] ||= Cart.new
  end
end