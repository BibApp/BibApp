class MembershipObserver < ActiveRecord::Observer
 
  # Anytime a Membership is created, we need to update Solr index
  #  for all Works associated with that membership
  def after_create(membership)
    #Asynchronously update Solr index for affected Works
    #  (This uses the Workling Plugin for asynchronization)
    IndexWorker.async_update_index(membership.person.works.verified)
  end
  
  # If a Membership is ever destroyed, we need to update Solr index
  #  for all Works associated with that membership
  def before_destroy(membership)
    #Asynchronously update Solr index for affected Works
    IndexWorker.async_update_index(membership.person.works.verified)
  end
 
end
