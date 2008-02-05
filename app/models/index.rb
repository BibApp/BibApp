class Index
  
  #### Solr ####
  
  # CONNECT
  # solr = Solr::Connection.new("http://localhost:8982/solr")
  
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
    :pk_i => :id,
    :id => Proc.new{|record| record.solr_id},
    :title_primary_t => :title_primary,
    :title_secondary_t => :title_secondary,
    :abstract_t => :abstract,
    :author_string_facet => Proc.new{|record| record.author_strings.collect{|as| as.name}},
    :publication_facet => Proc.new{|record| record.publication.authority.name},
    :publisher_facet => Proc.new{|record| record.publisher.authority.name},
    :type_facet => Proc.new{|record| record[:type]},
    :year_facet => Proc.new{|record| record.year}
  }
  
  class << self
    def batch_index
      records = Citation.find(
        :all, 
        :conditions => ["citation_state_id = ? and batch_index = ?", 3, 1])
      solr = Solr::Connection.new("http://localhost:8982/solr")
      records.each do |record|
        doc = Solr::Importer::Mapper.new(SOLR_MAPPING).map(record)
        solr.add(doc)
        record.batch_index = 0
        record.save_without_callbacks
      end
      solr.commit
    end
  
    def update_solr(record)
      solr = Solr::Connection.new("http://localhost:8982/solr")
      doc = Solr::Importer::Mapper.new(SOLR_MAPPING).map(record)
      solr.add(doc)
      solr.commit
    end
  
    def remove_from_solr(record)
      solr = Solr::Connection.new("http://localhost:8982/solr")
      solr.delete(record.solr_id)
      solr.commit
    end
  end
end
