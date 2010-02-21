class PublicationObserver < ActiveRecord::Observer
 
  # On create, map publisher_id to initial_publisher authority id
  def before_create(publication)
    unless publication.initial_publisher_id.nil?
      publication.publisher_id = Publisher.find(:first, :conditions => ["publishers.id = ?", publication.initial_publisher_id]).authority.id
    end
  end

  # Anytime a Publication is saved (during create or update)
  def after_save(publication)
    publication.update_authorities
    publication.update_machine_name
    publication.parse_identifiers
  end
    
end
