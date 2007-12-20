class SearchController < ApplicationController
  
  def index
    if params[:q]
      @query = params[:q]
      solr = Solr::Connection.new("http://localhost:8982/solr")
      
      if params[:fq]
        logger.debug "#{params.inspect}"
        @filter = params[:fq]
        @q = solr.query(
          @query, {
            :filter_queries => ["#{@filter}"], 
            :facets => {
              :fields => [:author_facet, :year_facet, :publication_facet, :type_facet], 
              :mincount => 1, 
              :limit => 10
            }
          })
      else
        @q = solr.query(
          @query, {
            :facets => {
              :fields => [:author_facet, :year_facet, :publication_facet, :type_facet],
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
      
      @author_facets = @q.data["facet_counts"]["facet_fields"]["author_facet"].sort{|a,b| b[1]<=>a[1]}
      @publication_facets = @q.data["facet_counts"]["facet_fields"]["publication_facet"].sort{|a,b| b[1]<=>a[1]}
      @type_facets = @q.data["facet_counts"]["facet_fields"]["type_facet"].sort{|a,b| b[1]<=>a[1]}
      @year_facets = @q.data["facet_counts"]["facet_fields"]["year_facet"].sort{|a,b| b <=> a}

      
    else
      # There's nothing to return
    end
  end
end
