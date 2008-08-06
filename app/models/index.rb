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
  ## citations = Citation.find(:all, :conditions => ["citation_state_id = 3"])
  ## citations.each{|c| Index.remove_from_solr(c)} 

  # REINDEX - Very long process
  # @TODO: Learn how to use Solr "replication"
  ## citations = Citation.find(:all, :conditions => ["citation_state_id = 3"])
  ## citations.each{|c| Index.update_solr(c)}
  
  # Default Solr Mapping 
  SOLR_MAPPING = {
    # Citation
    :pk_i => :id,  #store Citation ID as pk_i in Solr
    :id => Proc.new{|record| record.solr_id}, #create a unique Solr ID for Citation
    :title => :title_primary,
    :title_secondary => :title_secondary,
    :title_tertiary => :title_tertiary,
    :abstract => :abstract,
    :issn_isbn => Proc.new{|record| record.publication.authority.issn_isbn},
    
    # Citation Type (index as "Journal article" rather than "JournalArticle")
    :type_facet => Proc.new{|record| record[:type].underscore.humanize},
    
    # NameStrings
    :name_strings => Proc.new{|record| record.name_strings.collect{|ns| ns.name}},
    :name_string_facet_id => Proc.new{|record| record.name_strings.collect{|ns| build_facet_id(ns)}},
    
    # People
    :people => Proc.new{|record| record.people.collect{|p| p.first_last}},
    :person_facet_id => Proc.new{|record| record.people.collect{|p| build_facet_id(p)}},
    
    # Groups
    :groups => Proc.new{|record| record.people.collect{|p| p.groups.collect{|g| g.name}}.uniq.flatten},
    :group_facet_id => Proc.new{|record| record.people.collect{|p| p.groups.collect{|g| build_facet_id(g)}}.uniq.flatten},
    
    # Publication
    :publication => Proc.new{|record| record.publication.authority.name},
    :publication_facet_id => Proc.new{|record| build_facet_id(record.publication.authority)},
    
    # Publisher
    :publisher => Proc.new{|record| record.publisher.authority.name},
    :publisher_facet_id => Proc.new{|record| build_facet_id(record.publisher.authority)},
    
    # Keywords
    :keywords => Proc.new{|record| record.keywords.collect{|k| k.name}},
    :keyword_facet_id => Proc.new{|record| record.keywords.collect{|k| build_facet_id(k)}},
    
    # Tags
    :tags => Proc.new{|record| record.tags.collect{|k| k.name}},
    :tag_facet_id => Proc.new{|record| record.tags.collect{|k| build_facet_id(k)}}
  }
  
  # Mapping specific to dates
  #   Since dates are occasionally null they are only passed to Solr
  #   if the publication_date is *not* null.
  SOLR_DATE_MAPPING = {
    :year => Proc.new{|record| record.publication_date.year}
  }
  
  
  class << self
    def batch_index
      records = Citation.accepted.to_batch_index
      
      records.each do |record|
        if record.publication_date != nil
          #add dates to our mapping
          mapping = SOLR_MAPPING.merge(SOLR_DATE_MAPPING)
          doc = Solr::Importer::Mapper.new(mapping).map(record)
        else
          doc = Solr::Importer::Mapper.new(SOLR_MAPPING).map(record)
        end
        SOLRCONN.add(doc)
        record.batch_index = 0
        record.save_without_callbacks
      end
      SOLRCONN.commit
    end
    
    def start(page)
      if page.to_i < 2
        start = 0
      else 
        start = ((page.to_i-1)*10)
      end
    end
    
    #Reindex *everything* in Solr
    def index_all
      #Delete all existing records in Solr
      SOLRCONN.delete_by_query('*:*')
        
      #Reindex all citations again  
      records = Citation.accepted
      records.each do |record|
        if record.publication_date != nil
          #add dates to our mapping
          mapping = SOLR_MAPPING.merge(SOLR_DATE_MAPPING)
          doc = Solr::Importer::Mapper.new(mapping).map(record)
        else
          doc = Solr::Importer::Mapper.new(SOLR_MAPPING).map(record)
        end
        
        SOLRCONN.add(doc)
      end
      SOLRCONN.commit
      Index.build_spelling_suggestions
    end
    
    def build_spelling_suggestions
      SOLRCONN.send(Solr::Request::Spellcheck.new(:command => "rebuild", :query => "physcs"))
    end
  
    def update_solr(record)
      if record.publication_date != nil
          #add dates to our mapping
          mapping = SOLR_MAPPING.merge(SOLR_DATE_MAPPING)
          doc = Solr::Importer::Mapper.new(mapping).map(record)
      else
          doc = Solr::Importer::Mapper.new(SOLR_MAPPING).map(record)
      end
      
      SOLRCONN.add(doc)
      SOLRCONN.commit
    end
  
    def remove_from_solr(record)
      SOLRCONN.delete(record.solr_id)
      SOLRCONN.commit
    end

    #Fetch all documents matching a particular query, 
    # along with the facets.
    def fetch(query_string, filter, sort, page, facet_count, rows)
      
      #build our list of Solr query parameters
      query_params = {
            :query => query_string,
            :filter_queries => filter,
            :facets => {
              :fields => [
                :group_facet,
                :group_facet_id,
                :keyword_facet,
                :keyword_facet_id,
                :tag_facet,
                :tag_facet_id,
                :name_string_facet,
                :name_string_facet_id,
                :person_facet,
                :person_facet_id, 
                :publication_facet,
                :publication_facet_id,
                :publisher_facet,
                :publisher_facet_id,
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
    
    # Retrieve recommendations from Solr, based on current citation
    def recommendations(citation)
      r = SOLRCONN.send(Solr::Request::Standard.new(
        :query => "id:#{citation.solr_id}", 
        :mlt => {
          :count => 5, 
          :field_list => ["abstract","title"]
        })
      )

      docs = Array.new
      r.data["moreLikeThis"]["#{citation.solr_id}"]["docs"].each do |doc|
        citation = Citation.find(doc["pk_i"])
        docs << [citation, doc['score']]
      end
      
      return docs
    end
    
    #Generate a unique Solr Facet ID for the given object
    def build_facet_id(object)
      "#{object.class.name}-#{object.id}"
    end
    
    private
    
    #Process the documents returned from a Solr query, 
    # and extract out the facets we are interested in
    def process_response(query_response)
      # Processing returned docs:
      # 1. Extract the IDs from Solr response
      # 2. Find Citation objects via AR
      # 2. Load objects and Solr score for view
      
      docs = Array.new
      query_response.data["response"]["docs"].each do |doc|
        citation = Citation.find(doc["pk_i"])
        docs << [citation, doc['score']]
      end
      
      # Extract our facets from the query response.
      #  These come back as arrays of Solr::Response::Standard::FacetValue 
      #  objects (e.g.) {:name="Sage Publications", 'value'=20}
      facets = {
        :people         => query_response.field_facets("person_facet"),
        :person_id      => query_response.field_facets("person_facet_id"),
        :groups         => query_response.field_facets("group_facet"),
        :group_id       => query_response.field_facets("group_facet_id"),
        :names          => query_response.field_facets("name_string_facet"),
        :name_id        => query_response.field_facets("name_string_facet_id"),
        :publications   => query_response.field_facets("publication_facet"),
        :publication_id => query_response.field_facets("publication_facet_id"),
        :publishers     => query_response.field_facets("publisher_facet"),
        :publisher_id   => query_response.field_facets("publisher_facet_id"),
        :keywords       => query_response.field_facets("keyword_facet"),
        :keyword_id     => query_response.field_facets("keyword_facet_id"),
        :tags           => query_response.field_facets("tag_facet"),
        :tag_id         => query_response.field_facets("tag_facet_id"),
        :types          => query_response.field_facets("type_facet"),
        :years          => query_response.field_facets("year_facet")
      }
      
      return docs,facets
    end
  end
end
