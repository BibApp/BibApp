class GroupObserver < ActiveRecord::Observer
 
  # Anytime a Group is saved (during create or update), 
  #  we need to check if Solr needs to do reindexing
  def after_save(group)
    #Only update index if Group name has changed
    if group.name_changed?
      #Asynchronously update Solr index for Works
      #  (This uses the Workling Plugin for asynchronization)
      IndexWorker.async_update_index(group.works)
    end
  end
  
  # If a Group is ever destroyed, we need to update Solr index
  #  for all Works associated with that group
  def before_destroy(group)
    IndexWorker.async_update_index(group.works)
  end
    
end
