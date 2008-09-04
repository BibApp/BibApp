class PersonObserver < ActiveRecord::Observer
 
  # Anytime a Person is saved (during create or update), 
  #  we need to tell Solr to reindex his/her Works
  def after_save(person)
    #Only update index if Person info that Solr uses is updated
    #(NOTE: Image changes for People are caught by the attachment_observer)
    if person.first_name_changed? or person.last_name_changed?
      #Asynchronously update Solr index for verified works
      #  (This uses the Workling Plugin for asynchronization)
      IndexWorker.async_update_index(person.works.verified)
    end
  end
  
  # If a Person is ever destroyed, we need to also update Solr index
  #  for all of his/her verified works
  def before_destroy(person)
    IndexWorker.async_update_index(person.works.verified)
  end
    
end
