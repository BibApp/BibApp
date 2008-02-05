class AuthorStringsController < ApplicationController
  make_resourceful do 
    build :all
    
    before :new, :edit do
      @author_string_authorities = AuthorString.find(:all, :conditions => ["id = authority_id"], :order => "name")
    end
    
    before :index do 
      @author_strings = AuthorString.find(:all, :order => "name", :limit => 10)
    end
    response_for :index do |format|
      format.html # index.html
      format.xml { render :xml => @author_strings.to_xml }
    end

    before :show do 

      solr = Solr::Connection.new("http://localhost:8982/solr")
      filter = "author_facet:#{@author_string.name}"
      
      @q = solr.query("*:*",
        {
          :filter_queries => ["#{filter}"], 
          :facets => {
            :fields => [:author_string_facet, :year_facet, :publication_facet, :type_facet], 
            :mincount => 1, 
            :limit => 10
          }
        })
        
      @author_string_facets = {
        :values => @q.data["facet_counts"]["facet_fields"]["author_string_facet"].sort{|a,b| b[1]<=>a[1]},
        :name => "author_string"
      }
      
      @publication_facets = {
        :values => @q.data["facet_counts"]["facet_fields"]["publication_facet"].sort{|a,b| b[1]<=>a[1]},
        :name => "publication"
      }
      
      @type_facets = {
        :values => @q.data["facet_counts"]["facet_fields"]["type_facet"].sort{|a,b| b[1]<=>a[1]},
        :name => "type"
      }
      
      @year_facets = {
        :values => @q.data["facet_counts"]["facet_fields"]["year_facet"].sort{|a,b| b <=> a},
        :name => "year"
      }
      
    end
    
    response_for :show do |format|
      format.html # index.html
      format.xml { render :xml => @author_string.to_xml }
    end
  end
end
