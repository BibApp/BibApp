class PublicationObserver < ActiveRecord::Observer
 
  # Anytime a Publication is saved (during create or update), 
  #  we need to check if Solr needs to do reindexing
  def after_save(publication)
    #Only update index if Publication name or Authority has changed
    if publication.authority_id_changed? or publication.name_changed?
      #Asynchronously update Solr index for citations
      #  (This uses the Workling Plugin for asynchronization)
      IndexWorker.async_update_index(publication.citations)
    end
  end
  
  # If a Publication is ever destroyed, we need to update Solr index
  #  for all citations associated with that publication
  def before_destroy(publication)
    IndexWorker.async_update_index(publication.citations)
  end
    
end
