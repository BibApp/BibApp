class Index
  require 'solr'
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
  

  SOLR_MAPPING = {
    # Citation
    :pk_i => :id,
    :id => Proc.new{|record| record.solr_id},
    :title => :title_primary,
    :title_secondary => :title_secondary,
    :title_tertiary => :title_tertiary,
    :abstract => :abstract,
    :year => Proc.new{|record| record.publication_date.year},
    :issn_isbn => Proc.new{|record| record.publication.authority.issn_isbn},
    :publication => Proc.new{|record| record.publication.authority.name},
    :publisher => Proc.new{|record| record.publisher.authority.name},
    
    :type_facet => Proc.new{|record| record[:type]},
    :year_facet => Proc.new{|record| record.publication_date.year},
    :citation_id_facet => Proc.new{|record| record.solr_id},

    # SpellCheck
    :word => :abstract,
    
    # NameStrings
    :name_strings => Proc.new{|record| record.name_strings.collect{|ns| ns.name}},
    :name_string_facet => Proc.new{|record| record.name_strings.collect{|ns| ns.name}},
    :name_string_id_facet => Proc.new{|record| record.name_strings.collect{|ns| ns.solr_id}},
    
    # People
    :people => Proc.new{|record| record.people.collect{|p| p.first_last}},
    :person_facet => Proc.new{|record| record.people.collect{|p| p.first_last}},
    :person_id_facet => Proc.new{|record| record.people.collect{|p| p.solr_id}},
    
    # Groups
    :groups => Proc.new{|record| record.people.collect{|p| p.groups.collect{|g| g.name}}.uniq.flatten},
    :group_facet => Proc.new{|record| record.people.collect{|p| p.groups.collect{|g| g.name}}.uniq.flatten},
    :group_id_facet => Proc.new{|record| record.people.collect{|p| p.groups.collect{|g| g.solr_id}}.uniq.flatten},
    
    # Publication
    :publication_facet => Proc.new{|record| record.publication.authority.name},
    :publication_id_facet => Proc.new{|record| record.publication.authority.solr_id},
    
    # Publisher
    :publisher_facet => Proc.new{|record| record.publisher.authority.name},
    :publisher_id_facet => Proc.new{|record| record.publisher.authority.solr_id},
    
    # Keywords
    :keywords => Proc.new{|record| record.keywords.collect{|k| k.name}},
    :keyword_facet => Proc.new{|record| record.keywords.collect{|k| k.name}},
    :keyword_id_facet => Proc.new{|record| record.keywords.collect{|k| k.solr_id}},
    
    # Tags
    :tags => Proc.new{|record| record.tags.collect{|k| k.name}},
    :tag_facet => Proc.new{|record| record.tags.collect{|k| k.name}},
    :tag_id_facet => Proc.new{|record| record.tags.collect{|k| k.solr_id}}
  }
  
  SOLR_MAPPING_NO_DATE = {
    # Citation
    :pk_i => :id,
    :id => Proc.new{|record| record.solr_id},
    :title => :title_primary,
    :title_secondary => :title_secondary,
    :title_tertiary => :title_tertiary,
    :abstract => :abstract,
    :issn_isbn => Proc.new{|record| record.publication.authority.issn_isbn},
    :publication => Proc.new{|record| record.publication.authority.name},
    :publisher => Proc.new{|record| record.publisher.authority.name},
    
    :type_facet => Proc.new{|record| record[:type]},
    :citation_id_facet => Proc.new{|record| record.solr_id},
    
    # SpellCheck
    :word => :abstract,
    
    # NameStrings
    :name_strings => Proc.new{|record| record.name_strings.collect{|ns| ns.name}},
    :name_string_facet => Proc.new{|record| record.name_strings.collect{|ns| ns.name}},
    :name_string_id_facet => Proc.new{|record| record.name_strings.collect{|ns| ns.solr_id}},
    
    # People
    :people => Proc.new{|record| record.people.collect{|p| p.first_last}},
    :person_facet => Proc.new{|record| record.people.collect{|p| p.first_last}},
    :person_id_facet => Proc.new{|record| record.people.collect{|p| p.solr_id}},
    
    # Groups
    :groups => Proc.new{|record| record.people.collect{|p| p.groups.collect{|g| g.name}}.uniq.flatten},
    :group_facet => Proc.new{|record| record.people.collect{|p| p.groups.collect{|g| g.name}}.uniq.flatten},
    :group_id_facet => Proc.new{|record| record.people.collect{|p| p.groups.collect{|g| g.solr_id}}.uniq.flatten},
    
    # Publication
    :publication_facet => Proc.new{|record| record.publication.authority.name},
    :publication_id_facet => Proc.new{|record| record.publication.authority.solr_id},
    
    # Publisher
    :publisher_facet => Proc.new{|record| record.publisher.authority.name},
    :publisher_id_facet => Proc.new{|record| record.publisher.authority.solr_id},
    
    # Keywords
    :keywords => Proc.new{|record| record.keywords.collect{|k| k.name}},
    :keyword_facet => Proc.new{|record| record.keywords.collect{|k| k.name}},
    :keyword_id_facet => Proc.new{|record| record.keywords.collect{|k| k.solr_id}},
    
    # Tags
    :tags => Proc.new{|record| record.tags.collect{|k| k.name}},
    :tag_facet => Proc.new{|record| record.tags.collect{|k| k.name}},
    :tag_id_facet => Proc.new{|record| record.tags.collect{|k| k.solr_id}}
  }
  
  
  class << self
    def batch_index
      records = Citation.find(
        :all, 
        :conditions => ["citation_state_id = ? and batch_index = ?", 3, 1])
      
      records.each do |record|
        if record.publication_date != nil
          doc = Solr::Importer::Mapper.new(SOLR_MAPPING).map(record)
        else
          doc = Solr::Importer::Mapper.new(SOLR_MAPPING_NO_DATE).map(record)
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
      records = Citation.find(:all, :conditions => ["citation_state_id = ?", 3])  
      records.each do |record|
        if record.publication_date != nil
          doc = Solr::Importer::Mapper.new(SOLR_MAPPING).map(record)
        else
          doc = Solr::Importer::Mapper.new(SOLR_MAPPING_NO_DATE).map(record)
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
        doc = Solr::Importer::Mapper.new(SOLR_MAPPING).map(record)
      else
        doc = Solr::Importer::Mapper.new(SOLR_MAPPING_NO_DATE).map(record)
      end
      
      SOLRCONN.add(doc)
      SOLRCONN.commit
    end
  
    def remove_from_solr(record)
      SOLRCONN.delete(record.solr_id)
      SOLRCONN.commit
    end

    def fetch (query_string, filter, sort, page, facet_count, rows)
      begin
        q = SOLRCONN.send(Solr::Request::Standard.new(
          :query => query_string,
            :filter_queries => filter,
            :facets => {
              :fields => [
                :group_facet,
                :group_id_facet,
                :keyword_facet,
                :keyword_id_facet,
                :tag_facet,
                :tag_id_facet,
                :name_string_facet,
                :name_string_id_facet,
                :person_facet,
                :person_id_facet, 
                :publication_facet,
                :publication_id_facet,
                :publisher_facet,
                :publisher_id_facet,
                :type_facet,
                {:year_facet => {:sort => :term}}
              ], 
              :mincount => 1, 
              :limit => facet_count
            },
            :start => self.start(page),
            :sort => [{"#{sort}" => :descending}],
            :rows => rows
          ))
        
        # Rerun our search if the StandardRequestHandler came up empty...
        if q.data["response"]["docs"].size < 1
          q = SOLRCONN.send(Solr::Request::Dismax.new(
            :query => query_string,
              :filter_queries => filter,
              :facets => {
                :fields => [
                  :group_facet,
                  :group_id_facet,
                  :keyword_facet,
                  :keyword_id_facet,
                  :tag_facet,
                  :tag_id_facet,
                  :name_string_facet,
                  :name_string_id_facet,
                  :person_facet,
                  :person_id_facet, 
                  :publication_facet,
                  :publication_id_facet,
                  :publisher_facet,
                  :publisher_id_facet,
                  :type_facet,
                  {:year_facet => {:sort => :term}} 
                ], 
                :mincount => 1, 
                :limit => facet_count
              },
              :start => self.start(page),
              :sort => [{"#{sort}" => :descending}],
              :rows => rows
            ))
        end
        
        # Processing returned docs:
        # 1. Extract the IDs from Solr response
        # 2. Find Citation objects via AR
        # 2. Load objects and Solr score for view
      
        docs = Array.new
        q.data["response"]["docs"].each do |doc|
          citation = Citation.find(doc["pk_i"])
          docs << [citation, doc['score']]
        end
      
        facets = {
          :people         => q.field_facets("person_facet"),
          :person_id      => q.field_facets("person_id_facet"),
          :groups         => q.field_facets("group_facet"),
          :group_id       => q.field_facets("group_id_facet"),
          :names          => q.field_facets("name_string_facet"),
          :name_id        => q.field_facets("name_string_id_facet"),
          :publications   => q.field_facets("publication_facet"),
          :publication_id => q.field_facets("publication_id_facet"),
          :publishers     => q.field_facets("publisher_facet"),
          :publisher_id   => q.field_facets("publisher_id_facet"),
          :keywords       => q.field_facets("keyword_facet"),
          :keyword_id     => q.field_facets("keyword_id_facet"),
          :tags       => q.field_facets("tag_facet"),
          :tag_id     => q.field_facets("tag_id_facet"),
          :types          => q.field_facets("type_facet"),
          :years          => q.field_facets("year_facet")
        }
    rescue
      # If anything goes wrong (bad query terms for instance), we want to use the DismaxRequestHandler
      # which will help parse the "junk" from users' queries... and will return 0 results.
      
      q = SOLRCONN.send(Solr::Request::Dismax.new(
        :query => query_string,
          :filter_queries => filter,
          :facets => {
            :fields => [
              :group_facet,
              :group_id_facet,
              :keyword_facet,
              :keyword_id_facet,
              :tag_facet,
              :tag_id_facet,
              :name_string_facet,
              :name_string_id_facet,
              :person_facet,
              :person_id_facet, 
              :publication_facet,
              :publication_id_facet,
              :publisher_facet,
              :publisher_id_facet,
              :type_facet,
              {:year_facet => {:sort => :term}}
            ], 
            :mincount => 1, 
            :limit => facet_count
          },
          :start => self.start(page),
          :sort => [{"#{sort}" => :descending}],
          :rows => rows
        ))
        
      # Processing returned docs:
      # 1. Extract the IDs from Solr response
      # 2. Find Citation objects via AR
      # 2. Load objects and Solr score for view
      
      docs = Array.new
      q.data["response"]["docs"].each do |doc|
        citation = Citation.find(doc["pk_i"])
        docs << [citation, doc['score']]
      end
      
      facets = {
        :people         => q.field_facets("person_facet"),
        :person_id      => q.field_facets("person_id_facet"),
        :groups         => q.field_facets("group_facet"),
        :group_id       => q.field_facets("group_id_facet"),
        :names          => q.field_facets("name_string_facet"),
        :name_id        => q.field_facets("name_string_id_facet"),
        :publications   => q.field_facets("publication_facet"),
        :publication_id => q.field_facets("publication_id_facet"),
        :publishers     => q.field_facets("publisher_facet"),
        :publisher_id   => q.field_facets("publisher_id_facet"),
        :keywords       => q.field_facets("keyword_facet"),
        :keyword_id     => q.field_facets("keyword_id_facet"),
        :tags           => q.field_facets("tag_facet"),
        :tag_id         => q.field_facets("tag_id_facet"),
        :types          => q.field_facets("type_facet"),
        :years          => q.field_facets("year_facet")
      }
    end
      return q,docs,facets
    end
    
    def get_spelling_suggestions(query)
      spelling_suggestions = SOLRCONN.send(Solr::Request::Spellcheck.new(:query => query)).suggestions
      if spelling_suggestions == query
        spelling_suggestions = nil
      end
      
      return spelling_suggestions
    end
    
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
  end
end
