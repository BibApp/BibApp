class SearchController < ApplicationController

  def index
    # Default BibApp search method - ApplicationController
    search(params)

    respond_to do |format|
      format.html # Do HTML
      format.json
      format.yaml
      format.xml
      format.rdf
    end
  end

  def advanced
    normal_fields = [:title, :authors, :groups, :issn_isbn]
    fields = normal_fields << :keywords
    if !fields.detect { |f| params[f].present? }
      @q = nil
      return
    end

    logger.debug(params.inspect)
    # Process the params and redirect to /search
    @q = Array.new

    logger.debug(@q.inspect)
    # Add keywords to query
    if !params[:keywords].nil? && !params[:keywords].empty?
      @q << params[:keywords]
    end

    #Add 'normal' fields to query
    normal_fields.each do |field|
      if params[field].present?
        @q << "#{field}:#{params[field]}"
      end
    end

    # Add year to query
    start_date = params[:start_date].present? ? params[:start_date] : "*"
    end_date = params[:end_date].present? ? params[:end_date] : "*"

    # Only if we have a non-default start_date or end_date add it to @q
    unless start_date == "*" and end_date == "*"
      @q << "year:[#{start_date} TO #{end_date}]"
    end

    logger.debug(@q.inspect)
    # Redirect to /search with properly formatted solr standard request params
    redirect_to search_path(:q => @q.join(", "))
  end

end