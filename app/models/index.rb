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
  # facets = q.data["facet_counts"]["facet_fields"]["author_facet"]
  # @author_facets = q.data["facet_counts"]["facet_fields"]["author_facet"].sort{|a,b| b[1]<=>a[1]}

  # DELETE INDEX - Very long process
  # @TODO: Learn how to use Solr "replication"
  ## citations = Citation.find(:all, :conditions => ["citation_state_id = 3"])
  ## citations.each{|c| c.remove_from_solr} 

  # REINDEX - Very long process
  # @TODO: Learn how to use Solr "replication"
  ## citations = Citation.find(:all, :conditions => ["citation_state_id = 3"])
  ## citations.each{|c| c.update_solr}
  

  SOLR_MAPPING = {
    # Stored Fields
    :pk_i => :id,
    :id => Proc.new{|record| record.solr_id},
    :title => :title_primary,
    :abstract => :abstract,
    
    # Dynamic Fields
    :title_t => :title_primary,
    :abstract_t => :abstract,
    :title_secondary_t => :title_secondary,
    :name_string_facet => Proc.new{|record| record.name_strings.collect{|ns| ns.name}},
    :person_facet => Proc.new{|record| record.people.collect{|p| p.first_last}},
    :person_id_facet => Proc.new{|record| record.people.collect{|p| p.solr_id}},
    :publication_facet => Proc.new{|record| record.publication.authority.name},
    :publisher_facet => Proc.new{|record| record.publisher.authority.name},
    :type_facet => Proc.new{|record| record[:type]},
    :year_facet => Proc.new{|record| record.year},
    :word => :abstract
  }
  
  class << self
    def batch_index
      records = Citation.find(
        :all, 
        :conditions => ["citation_state_id = ? and batch_index = ?", 3, 1])
      
      records.each do |record|
        doc = Solr::Importer::Mapper.new(SOLR_MAPPING).map(record)
        SOLRCONN.add(doc)
        record.batch_index = 0
        record.save_without_callbacks
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
    
    def get_spelling_suggestions(query)
      spelling_suggestions = SOLRCONN.send(Solr::Request::Spellcheck.new(:query => query)).suggestions
      if spelling_suggestions == query
        spelling_suggestions = nil
      end
      return spelling_suggestions
    end
  end
end
