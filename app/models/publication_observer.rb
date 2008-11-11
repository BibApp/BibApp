class PublicationObserver < ActiveRecord::Observer
 
  # Anytime a Publication is saved (during create or update)
  def after_save(pub)
    pub.update_authorities
    pub.update_machine_name
  end
    
end
