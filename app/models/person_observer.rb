class PersonObserver < ActiveRecord::Observer
 
  #Called after Person is created or updated
  def after_save(person)
    #Update machine_name as necesary
    person.update_machine_name
  end
    
end
