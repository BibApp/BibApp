class SearchController < ApplicationController  
  def index
    if params[:q]
      @query = params[:q]
      @sort = params[:sort] || "score desc"
      @fetch = @query + ";" + @sort
      @filter = params[:fq] || ""
      @filter = @filter.split("+>+").each{|f| f.strip!}
      @q,@docs,@facets = Index.fetch(@fetch, @filter, @sort)

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
