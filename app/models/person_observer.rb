class PersonObserver < ActiveRecord::Observer
 
  #Called after Person is created or updated
  def after_save(person)
    #Update memberships if person becomes inactive
    person.update_memberships_end_dates 
    #Update machine_name as necessary
    person.update_machine_name
  end
    
end
