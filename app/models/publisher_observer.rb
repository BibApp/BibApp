class PublisherObserver < ActiveRecord::Observer
 
  # Anytime a Publisher is saved (during create or update), 
  #  we need to check if Solr needs to do reindexing
  def after_save(publisher)
    #Only update index if Publisher name or Authority has changed
    if publisher.authority_id_changed? or publisher.name_changed?
      #Asynchronously update Solr index for Works
      #  (This uses the Workling Plugin for asynchronization)
      IndexWorker.async_update_index(publisher.works)
    end
  end
  
  # If a Publisher is ever destroyed, we need to update Solr index
  #  for all works associated with that publisher
  def before_destroy(publisher)
    IndexWorker.async_update_index(publisher.works)
  end
    
end
