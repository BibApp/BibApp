class IndexObserver < ActiveRecord::Observer
  require 'index.rb'
  
  observe Work
  
  def after_save(record)
    if record.batch_index? || !record.accepted?
      # Do not update
    else
      Index.update_solr(record)
    end
  end
  
  def after_destroy(record)
    Index.remove_from_solr(record)
  end
end
