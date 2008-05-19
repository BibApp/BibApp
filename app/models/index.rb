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
    :abstract => :abstract,
    :year => Proc.new{|record| record.publication_date.year},
    :type_facet => Proc.new{|record| record[:type]},
    :year_facet => Proc.new{|record| record.publication_date.year},
    :title_t => :title_primary,
    :abstract_t => :abstract,
    :title_secondary_t => :title_secondary,
    :citation_id_facet => Proc.new{|record| record.solr_id},

    # SpellCheck
    :word => :abstract,
    
    # NameString
    :name_string_facet => Proc.new{|record| record.name_strings.collect{|ns| ns.name}},
    :name_string_id_facet => Proc.new{|record| record.name_strings.collect{|ns| ns.solr_id}},
    
    # Person
    :person_facet => Proc.new{|record| record.people.collect{|p| p.first_last}},
    :person_id_facet => Proc.new{|record| record.people.collect{|p| p.solr_id}},
    
    # Group
    :group_facet => Proc.new{|record| record.people.collect{|p| p.groups.collect{|g| g.name}}.uniq.flatten},
    :group_id_facet => Proc.new{|record| record.people.collect{|p| p.groups.collect{|g| g.solr_id}}.uniq.flatten},
    
    # Publication
    :publication_facet => Proc.new{|record| record.publication.authority.name},
    :publication_id_facet => Proc.new{|record| record.publication.authority.solr_id},
    
    # Publisher
    :publisher_facet => Proc.new{|record| record.publisher.authority.name},
    :publisher_id_facet => Proc.new{|record| record.publisher.authority.solr_id},
    
    # Keyword
    :keyword_facet => Proc.new{|record| record.keywords.collect{|k| k.name}},
    :keyword_id_facet => Proc.new{|record| record.keywords.collect{|k| k.solr_id}}
  }
  
  SOLR_MAPPING_NO_DATE = {
    # Citation
    :pk_i => :id,
    :id => Proc.new{|record| record.solr_id},
    :title => :title_primary,
    :abstract => :abstract,
    :type_facet => Proc.new{|record| record[:type]},
    :title_t => :title_primary,
    :abstract_t => :abstract,
    :title_secondary_t => :title_secondary,
    :citation_id_facet => Proc.new{|record| record.solr_id},

    # SpellCheck
    :word => :abstract,
    
    # NameString
    :name_string_facet => Proc.new{|record| record.name_strings.collect{|ns| ns.name}},
    :name_string_id_facet => Proc.new{|record| record.name_strings.collect{|ns| ns.solr_id}},
    
    # Person
    :person_facet => Proc.new{|record| record.people.collect{|p| p.first_last}},
    :person_id_facet => Proc.new{|record| record.people.collect{|p| p.solr_id}},
    
    # Group
    :group_facet => Proc.new{|record| record.people.collect{|p| p.groups.collect{|g| g.name}}.uniq.flatten},
    :group_id_facet => Proc.new{|record| record.people.collect{|p| p.groups.collect{|g| g.solr_id}}.uniq.flatten},
    
    # Publication
    :publication_facet => Proc.new{|record| record.publication.authority.name},
    :publication_id_facet => Proc.new{|record| record.publication.authority.solr_id},
    
    # Publisher
    :publisher_facet => Proc.new{|record| record.publisher.authority.name},
    :publisher_id_facet => Proc.new{|record| record.publisher.authority.solr_id},
    
    # Keyword
    :keyword_facet => Proc.new{|record| record.keywords.collect{|k| k.name}},
    :keyword_id_facet => Proc.new{|record| record.keywords.collect{|k| k.solr_id}}
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
    
    #Reindex *everything* in Solr
    def index_all
      #Delete all existing records in Solr
      SOLRCONN.delete_by_query('*:*')
        
      #Reindex all citations again  
      records = Citation.find(:all, :conditions => ["citation_state_id = ?", 3])  
      records.each do |record|
        doc = Solr::Importer::Mapper.new(SOLR_MAPPING).map(record)
        SOLRCONN.add(doc)
      end
      SOLRCONN.commit
    end
  
    def update_solr(record)
      doc = Solr::Importer::Mapper.new(SOLR_MAPPING).map(record)
      SOLRCONN.add(doc)
      SOLRCONN.commit
    end
  
    def remove_from_solr(record)
      SOLRCONN.delete(record.solr_id)
      SOLRCONN.commit
    end

    def fetch (query_string, filter, sort)
      if !filter.empty?
        q = SOLRCONN.query(
          query_string, {
            :filter_queries => filter, 
            :facets => {
              :fields => [
                :group_facet,
                :group_id_facet,
                :keyword_facet,
                :keyword_id_facet,
                :name_string_facet,
                :name_string_id_facet,
                :person_facet,
                :person_id_facet, 
                :publication_facet,
                :publication_id_facet,
                :publisher_facet,
                :publisher_id_facet,
                :type_facet,
                :year_facet 
              ], 
              :mincount => 1, 
              :limit => 10
            }
          })
      else
        q = SOLRCONN.query(
          query_string, {
            :facets => {
              :fields => [
                :group_facet,
                :group_id_facet,
                :keyword_facet,
                :keyword_id_facet,
                :name_string_facet,
                :name_string_id_facet,
                :person_facet,
                :person_id_facet, 
                :publication_facet,
                :publication_id_facet,
                :publisher_facet,
                :publisher_id_facet,
                :type_facet,
                :year_facet
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
        :types          => q.field_facets("type_facet"),
        :years          => q.field_facets("year_facet")
      }
      return q,docs,facets
    end
    
    def get_spelling_suggestions(query)
      spelling_suggestions = SOLRCONN.send(Solr::Request::Spellcheck.new(:query => query)).suggestions
      if spelling_suggestions == query
        spelling_suggestions = nil
      end
      return spelling_suggestions
    end
  end
end
