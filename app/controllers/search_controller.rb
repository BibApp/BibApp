class SearchController < ApplicationController
  
  def index
    if params[:q]
      @query = params[:q]
      solr = Solr::Connection.new("http://localhost:8982/solr")
      @sort = prepare_sort_params(params[:sort]) || ";flaggeds_facet desc, score desc"
      @query_and_sort = @query + @sort
      
      @filters = params[:fq] || []      

      if params[:fq]
        @filters = @filters.split(",")
        logger.debug "#{params.inspect}"
        @q = solr.query(
          @query_and_sort, {
            :filter_queries => @filters, 
            :facets => {
              :fields => [
                :author_facet, 
                :year_facet, 
                :publication_facet, 
                :type_facet
              ], 
            :mincount => 1, 
            :limit => 10
          }
        })
      else
        @q = solr.query(
          @query_and_sort, {
            :facets => {
              :fields => [
                :author_facet, 
                :year_facet, 
                :publication_facet, 
                :type_facet
              ],
            :mincount => 1,
            :limit => 10
          }
        })
      end
      
      # Processing returned docs:
      # 1. Extract the IDs from Solr response
      # 2. Find Citation objects via AR
      # 2. Load objects and Solr score for view
      
      @docs = Array.new
      @q.docs.each do |doc|
        citation = citation = Citation.find(doc["pk_i"][0])
        @docs << [citation, doc['score']]
      end
      
      @facets = [
        {
          :name => "author_facets",
          :data => @q.data["facet_counts"]["facet_fields"]["author_facet"].sort{|a,b| b[1]<=>a[1]}
        },
        {
          :name => "publication_facets",
          :data => @q.data["facet_counts"]["facet_fields"]["publication_facet"].sort{|a,b| b[1]<=>a[1]}
        },
        {
          :name => "type_facets",
          :data => @q.data["facet_counts"]["facet_fields"]["type_facet"].sort{|a,b| b[1]<=>a[1]}
        },
        {
          :name => "year_facets",
          :data => @q.data["facet_counts"]["facet_fields"]["year_facet"].sort{|a,b| b <=> a}
        }
      ]
    else
      # There's nothing to return
    end
  end
  
  private
  
  def prepare_sort_params(sort)
    sort
  end
end
