class SearchController < ApplicationController

  # Find the @cart variable, used to display "add" or "remove" links for saved citations  
  before_filter :find_cart, :only => [:index]
  
  def index
    if params[:q]

      # Default SolrRuby params
      @query        = params[:q] # User query
      @filter       = params[:fq] || ""
      @filter_no_strip = params[:fq] || ""
      @filter       = @filter.split("+>+").each{|f| f.strip!}
      @sort         = params[:sort] || "score"
      @sort         = "score" if @sort.empty?
      @page         = params[:page] || 0
      @facet_count  = params[:facet_count] || 50
      @rows         = params[:rows] || 10
      @export       = params[:export] || ""
      
      @q,@citations,@facets = Index.fetch(@query, @filter, @sort, @page, @facet_count, @rows)

      @spelling_suggestions = Index.get_spelling_suggestions(@query)

      @spelling_suggestions.each do |suggestion|
        # if suggestion matches query don't suggest...
        if suggestion.downcase == @query.downcase
          @spelling_suggestions.delete(suggestion)
        end
      end
      
      if @export && !@export.empty?
        x = CitationExport.new
        @citations = x.drive_csl(@export, @citations)
      end
    else
      @q = nil
      # There's nothing to return
    end
  end
  
  private
  
  def find_cart
    @cart = session[:cart] ||= Cart.new
  end
end