class Index
  #Require Solr, if it's defined.  
  # This allows us to make solr-ruby a Gem Dependency, as suggested in this blog:
  # http://www.webficient.com/2008/7/11/rails-gem-dependencies-and-plugin-errors
  require 'solr' if defined? Solr
  
  #### Solr ####
  
  # CONNECT
  # SOLRCONN = Solr::Connection.new("http://localhost:8983/solr")
  # SOLRCONN lives in initializers
  
  # SEARCH
  # q = solr.query("complex", :facets => {:zeros => false, :fields => [:author_facet]})
  # q = solr.query("comp*", {:field_list => ["author_facet"]})
  # q = solr.query("comp*", {:filter_queries => ["type_s:JournalArticle"]})
  
  # VIEW FACETS
  # @author_facets = @q.field_facets("name_string_facet")

  # DELETE INDEX - Very long process
  # @TODO: Learn how to use Solr "replication"
  ## works.each{|c| Index.remove_from_solr(c)} 

  # REINDEX - Very long process
  # @TODO: Learn how to use Solr "replication"
  ## works.each{|c| Index.update_solr(c)}
  
  # Default Solr Mapping 
  SOLR_MAPPING = {
    # Work
    :pk_i => :id,  #store Work ID as pk_i in Solr
    :id => Proc.new{|record| record.solr_id}, #create a unique Solr ID for Work
    :title => :title_primary,
    :title_secondary => :title_secondary,
    :title_tertiary => :title_tertiary,
    :issue => :issue,
    :volume => :volume,
    :start_page => :start_page,
    :abstract => :abstract,
    :status => :work_state_id,
    :issn_isbn => Proc.new{|record| record.publication.authority.issn_isbn},
    
    # Work Type (index as "Journal article" rather than "JournalArticle")
    :type => Proc.new{|record| record[:type].underscore.humanize},
    
    # NameStrings
    :name_strings => Proc.new{|record| record.name_strings.collect{|ns| ns.name}},
    :name_string_id => Proc.new{|record| record.name_strings.collect{|ns| ns.id}},
    :name_strings_data => Proc.new{|record| record.name_strings.collect{|ns| ns.to_solr_data}},
    
    # People
    :people => Proc.new{|record| record.people.collect{|p| p.first_last}},
    :person_id => Proc.new{|record| record.people.collect{|p| p.id}},
    :people_data => Proc.new{|record| record.people.collect{|p| p.to_solr_data}},
    
    # Groups
    :groups => Proc.new{|record| record.people.collect{|p| p.groups.collect{|g| g.name}}.uniq.flatten},
    :group_id => Proc.new{|record| record.people.collect{|p| p.groups.collect{|g| g.id}}.uniq.flatten},
    :groups_data => Proc.new{|record| record.people.collect{|p| p.groups.collect{|g| g.to_solr_data}}.uniq.flatten},
    
    # Publication
    :publication => Proc.new{|record| record.publication.authority.name},
    :publication_id => Proc.new{|record| record.publication.authority.id},
    :publication_data => Proc.new{|record| record.publication.authority.to_solr_data},
    
    # Publisher
    :publisher => Proc.new{|record| record.publisher.authority.name},
    :publisher_id => Proc.new{|record| record.publisher.authority.id},
    :publisher_data => Proc.new{|record| record.publisher.authority.to_solr_data},
    
    # Keywords
    :keywords => Proc.new{|record| record.keywords.collect{|k| k.name}},
    :keyword_id => Proc.new{|record| record.keywords.collect{|k| k.id}},
    
    # Tags
    :tags => Proc.new{|record| record.tags.collect{|t| t.name}},
    :tag_id => Proc.new{|record| record.tags.collect{|t| t.id}}
  }
  
  # Mapping specific to dates
  #   Since dates are occasionally null they are only passed to Solr
  #   if the publication_date is *not* null.
  SOLR_DATE_MAPPING = {
    :year => Proc.new{|record| record.publication_date.year}
  }
  
  
  class << self
    
    # Index all accepted Works which have been flagged for batch indexing
    def batch_index
      records = Work.accepted.to_batch_index
      
      #Batch index 100 records at a time...wait to commit till the end.
      records.each_slice(100) do |records_slice|
        batch_update_solr(records_slice, false)
      end
      
      #Mark all these Works as indexed & commit changes to Solr
      records.indexed
      SOLRCONN.commit
    end
    
    def start(page)
      if page.to_i < 2
        start = 0
      else 
        start = ((page.to_i-1)*10)
      end
    end
    
    #Re-index *everything* in Solr
    #  This method is useful in case your Solr index 
    #  gets out of sync with your DB
    def index_all
      #Delete all existing records in Solr
      SOLRCONN.delete_by_query('*:*')
        
      #Reindex all accepted Works again  
      records = Work.accepted
      
      #Do a batch update, 100 records at a time...wait to commit till the end.
      records.each_slice(100) do |records_slice|
        batch_update_solr(records_slice, false)
      end
      
      SOLRCONN.commit
      Index.build_spelling_suggestions
    end
    
    def build_spelling_suggestions
      SOLRCONN.send(Solr::Request::Spellcheck.new(:command => "rebuild", :query => "physcs"))
    end
  
    #Update a single record in Solr
    # (for bulk updating, use 'batch_update_solr', as it is faster)
    def update_solr(record, commit_records=true)
      if record.publication_date != nil
          #add dates to our mapping
          mapping = SOLR_MAPPING.merge(SOLR_DATE_MAPPING)
          doc = Solr::Importer::Mapper.new(mapping).map(record)
      else
          doc = Solr::Importer::Mapper.new(SOLR_MAPPING).map(record)
      end
      
      SOLRCONN.add(doc)
      SOLRCONN.commit if commit_records
    end
    
    #Batch update several records with a single request to Solr
    def batch_update_solr(records, commit_records=true)
      docs = Array.new
      records.each do |record|
        if record.publication_date != nil
          #add dates to our mapping
          mapping = SOLR_MAPPING.merge(SOLR_DATE_MAPPING)
          doc = Solr::Importer::Mapper.new(mapping).map(record)
        else
          doc = Solr::Importer::Mapper.new(SOLR_MAPPING).map(record)
        end
        
        #append to array of docs to update
        docs << doc
      end
       
      #Send one update request for all docs!
      request = Solr::Request::AddDocument.new(docs)
      SOLRCONN.send(request)
      SOLRCONN.commit if commit_records
    end
    
    #Remove a single record from Solr
    def remove_from_solr(record)
      SOLRCONN.delete(record.solr_id)
      SOLRCONN.commit
    end

    
    def optimize_index
      SOLRCONN.optimize
    end
    
    #Fetch all documents matching a particular query, 
    # along with the facets.
    def fetch(query_string, filter, sort, page, facet_count, rows)
      
      #build our list of Solr query parameters
      # Note: the various '*_facet' and '*_facet_data' fields
      # are auto-generated by our Solr schema settings (see schema.xml)
      query_params = {
            :query => query_string,
            :filter_queries => filter,
            :facets => {
              :fields => [
                :group_facet,
                :group_facet_data,
                :keyword_facet,
                :tag_facet,
                :name_string_facet,
                :name_string_facet_data,
                :person_facet,
                :person_facet_data,
                :publication_facet,
                :publication_facet_data,
                :publisher_facet,
                :publisher_facet_data,
                :type_facet,
                {:year_facet => {:sort => :term}}
              ], 
              :mincount => 1, 
              :limit => facet_count
            },
            :start => self.start(page),
            :sort => [{"#{sort}" => :descending}],
            :rows => rows
      }
      
      begin
        # First, try query with StandardRequestHandler
        q = SOLRCONN.send(Solr::Request::Standard.new(query_params))
        
        # Rerun our search if the StandardRequestHandler came up empty...
        if q.data["response"]["docs"].size < 1
          # Try it instead with DismaxRequestHandler, which is more forgiving
          q = SOLRCONN.send(Solr::Request::Dismax.new(query_params))
        end
        
        # Processing returned docs and extract facets
        docs, facets = process_response(q)
        
      rescue
        # If anything goes wrong (bad query terms for instance), we want to use the DismaxRequestHandler
        # which will help parse the "junk" from users' queries... and will return 0 results.
        q = SOLRCONN.send(Solr::Request::Dismax.new(query_params))
          
        # Processing returned docs and extract facets
        docs, facets = process_response(q)
      end
   
      # return query response, docs and facets
      return q,docs,facets
    end
    
    #Retrieve Spelling Suggestions from Solr, based on query
    def get_spelling_suggestions(query)
      spelling_suggestions = SOLRCONN.send(Solr::Request::Spellcheck.new(:query => query)).suggestions
      if spelling_suggestions == query
        spelling_suggestions = nil
      end
      
      return spelling_suggestions
    end
    
    def fetch_by_solr_id(solr_id)
      docs = SOLRCONN.send(Solr::Request::Standard.new(:query => "id:#{solr_id}")).data["response"]["docs"]
    end
    
    # Retrieve recommendations from Solr, based on current Work
    def recommendations(work)
      
      #Send a "more like this" query to Solr
      r = SOLRCONN.send(Solr::Request::Standard.new(
        :query => "id:#{work.solr_id}", 
        :mlt => {
          :count => 5, 
          :field_list => ["abstract","title"]
        })
      )
   
      docs = Array.new
      
      #Add related docs to an array, if any like this one were found
      unless r.data["moreLikeThis"].empty? or r.data["moreLikeThis"]["#{work.solr_id}"].empty?
        r.data["moreLikeThis"]["#{work.solr_id}"]["docs"].each do |doc|
          work = Work.find(doc["pk_i"])
          docs << [work, doc['score']]
        end
      end
       
      return docs
    end
    
    
    # Output a Work as if it came directly from Solr index
    # This is useful if a View has the full Work object
    # but still wants to take advantage of the
    # '/views/shared/work' partial (which expects the
    # work data to be in the Hash format Solr returns).
    def work_to_solr_hash(work)
      # Transform Work using our Solr Mapping
      if work.publication_date != nil
        #add dates to our mapping
        mapping = SOLR_MAPPING.merge(SOLR_DATE_MAPPING)
        doc = Solr::Importer::Mapper.new(mapping).map(work)
      else
        doc = Solr::Importer::Mapper.new(SOLR_MAPPING).map(work)
      end
      
      # We now have a hash with symbols (e.g. :title) for keys.
      # However, we need one with strings (e.g. "title") for keys.
      # So, we use HashWithIndifferentAccess to convert to a 
      # hash which has strings for keys.
      solr_hash = HashWithIndifferentAccess.new(doc).to_hash
      
      return solr_hash
    end
    
    private
    
    #Process the response returned from a Solr query, 
    # and extract out the documents & facets
    def process_response(query_response)

      #get the documents returned by Solr query
      docs = query_response.data["response"]["docs"]
      
      # Extract our facets from the query response.
      #  These come back as arrays of Solr::Response::Standard::FacetValue 
      #  objects (e.g.) {:name="Sage Publications", 'value'=20}
      #  Note: the various '*_facet' and '*_facet_data' fields
      #  are auto-generated by our Solr schema settings (see schema.xml)
      facets = {
        :people         => query_response.field_facets("person_facet"),
        :people_data    => query_response.field_facets("person_facet_data"),
        :groups         => query_response.field_facets("group_facet"),
        :groups_data    => query_response.field_facets("group_facet_data"),
        :names          => query_response.field_facets("name_string_facet"),
        :names_data     => query_response.field_facets("name_string_facet_data"),
        :publications   => query_response.field_facets("publication_facet"),
        :publications_data => query_response.field_facets("publication_facet_data"),
        :publishers     => query_response.field_facets("publisher_facet"),
        :publishers_data  => query_response.field_facets("publisher_facet_data"),
        :keywords       => query_response.field_facets("keyword_facet"),
        :tags           => query_response.field_facets("tag_facet"),
        :types          => query_response.field_facets("type_facet"),
        :years          => query_response.field_facets("year_facet")
      }
      
      return docs,facets
    end
  end
end
