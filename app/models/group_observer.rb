class GroupObserver < ActiveRecord::Observer
 
  #Called after Group is created or updated
  def after_save(group)
    
    #Update machine_name as necesary
    group.update_machine_name
  end
    
end
