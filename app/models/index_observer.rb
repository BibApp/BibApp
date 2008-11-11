class IndexObserver < ActiveRecord::Observer
  require 'index.rb'
  
  observe Work
  
  def after_save(record)
    record.logger.debug("\n\n === AFTER-SAVE IN INDEX OBSERVER ===\n\n")
    #Only re-index when something has changed, and record is not marked for batch indexing
    unless !record.batch_index? and record.changed?
      Index.update_solr(record)
    end
  end
  
  def after_destroy(record)
    Index.remove_from_solr(record)
  end
end
