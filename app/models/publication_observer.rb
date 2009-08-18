class PublicationObserver < ActiveRecord::Observer
 
  # Anytime a Publication is saved (during create or update)
  def after_save(publication)
    publication.update_authorities
    publication.update_machine_name
    publication.parse_identifiers
  end
    
end
