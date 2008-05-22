class SearchController < ApplicationController  
  def index
    if params[:q]
      @query = params[:q]
      @filter = params[:fq] || ""
      @filter = @filter.split("+>+").each{|f| f.strip!}
      @sort = params[:sort] || "score"
      @page = params[:page] || 0
      @q,@docs,@facets = Index.fetch(@query, @filter, @sort, @page)

      @spelling_suggestions = Index.get_spelling_suggestions(@query)

      @spelling_suggestions.each do |suggestion|
        # if suggestion matches query don't suggest...
        if suggestion.downcase == @query.downcase
          @spelling_suggestions.delete(suggestion)
        end
      end
    else
      @q = nil
      # There's nothing to return
    end
  end
end
