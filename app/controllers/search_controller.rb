class SearchController < ApplicationController
  
  def index
    
    @query  = params[:q] || []
    @filter = params[:fq] || ""
    @filter = @filter.split("+>+").each{|f| f.strip!}

    if params[:q]
      solr = Solr::Connection.new("http://localhost:8982/solr")
      
      if params[:fq]
        @q = solr.query(
          @query, {
            :filter_queries => @filter, 
            :facets => {
              :fields => [:author_string_facet, :year_facet, :publication_facet, :type_facet], 
              :mincount => 1, 
              :limit => 10
            }
          })
      else
        @q = solr.query(
          @query, {
            :facets => {
              :fields => [:author_string_facet, :year_facet, :publication_facet, :type_facet],
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
      logger.debug "Docs: #{@q.inspect}"
      @q.data["response"]["docs"].each do |doc|
        citation = citation = Citation.find(doc["pk_i"][0])
        @docs << [citation, doc['score']]
      end
      
      @facets = {
        "author_string" => @q.data["facet_counts"]["facet_fields"]["author_string_facet"].sort{|a,b| b[1]<=>a[1]},
        "publication" => @q.data["facet_counts"]["facet_fields"]["publication_facet"].sort{|a,b| b[1]<=>a[1]},
        "type" => @q.data["facet_counts"]["facet_fields"]["type_facet"].sort{|a,b| b[1]<=>a[1]},
        "year" => @q.data["facet_counts"]["facet_fields"]["year_facet"].sort{|a,b| b <=> a}
      }
      
    else
      # There's nothing to return
    end
  end
end