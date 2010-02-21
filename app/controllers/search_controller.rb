class SearchController < ApplicationController
  
  def index
    # Default BibApp search method - ApplicationController
    search(params)
    
    respond_to do |format|
      format.html # Do HTML
      format.yaml { render :yaml => @works }
      format.json {
      
        # Too much processing move to view!
        @items = Hash.new
        @items["items"] = Array.new
        @works.each do |work|
          item = Hash.new
          item["type"] = work["type"]
          item["label"] = work["title"]
          item["authors"] = work["authors"]
          item["year"] = work["year"]
          item["publication"] = work["publication"]
          @items["items"] << item
        end
        
        render :json => @items, :callback => params[:callback] 
      }
      format.xml  # Do XML
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

end