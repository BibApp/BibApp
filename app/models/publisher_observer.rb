class PublisherObserver < ActiveRecord::Observer
 
  # Anytime a Publisher is saved (during create or update)
  def after_save(publisher)
    publisher.update_authorities
    publisher.update_machine_name
  end
end
