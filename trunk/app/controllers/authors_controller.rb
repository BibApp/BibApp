class AuthorsController < ApplicationController
  make_resourceful do 
    build :all
    
    before :new, :edit do
      @author_authorities = Author.find(:all, :conditions => ["id = authority_id"], :order => "name")
    end
    
    before :index do 
      @authors = Author.find(:all, :order => "name", :limit => 10)
    end
    response_for :index do |format|
      format.html # index.html
      format.xml { render :xml => @authors.to_xml }
    end

    before :show do 

      solr = Solr::Connection.new("http://localhost:8982/solr")
      filter = "author_facet:#{@author.name}"
      
      @q = solr.query("*:*",
        {
          :filter_queries => ["#{filter}"], 
          :facets => {
            :fields => [:author_facet, :year_facet, :publication_facet, :type_facet], 
            :mincount => 1, 
            :limit => 10
          }
        })
        
      @author_facets = {
        :values => @q.data["facet_counts"]["facet_fields"]["author_facet"].sort{|a,b| b[1]<=>a[1]},
        :name => "author"
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
      format.xml { render :xml => @author.to_xml }
    end
  end
end
