class AttachmentObserver < ActiveRecord::Observer
 
  # Anytime an Attachment is saved (during create or update), 
  #  we need to check if Solr needs to do reindexing
  def after_save(attachment)
    #Only update index if this is an Image attachment for a Person
    if attachment.asset.kind_of?(Person) and attachment.kind_of?(Image)
      #Asynchronously update Solr index for Person's verified citations
      #  (This uses the Workling Plugin for asynchronization)
      IndexWorker.async_update_index(attachment.asset.citations.verified) 
    end
  end
  
  # If a Person is ever destroyed, we need to also update Solr index
  #  for all of his/her verified citations
  def before_destroy(attachment)
    #Only update index if this is an Image attachment for a Person
    if attachment.asset.kind_of?(Person) and attachment.kind_of?(Image)
      IndexWorker.async_update_index(attachment.asset.citations.verified)
    end
  end
    
end
