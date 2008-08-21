class PersonObserver < ActiveRecord::Observer
 
  # Anytime a Person is saved (during create or update), 
  #  we need to tell Solr to reindex his/her citations
  def after_save(person)
    #Asynchronously update Solr index for verified citations
    #  (This uses the Workling Plugin for asynchronization)
    IndexWorker.async_update_index(person.citations.verified) #if verfied_citations.size > 0
  end
  
  # If a Person is ever destroyed, we need to also update Solr index
  #  for all of his/her verified citations
  def before_destroy(person)
    IndexWorker.async_update_index(person.citations.verified) #if verfied_citations.size > 0
  end
  
end
