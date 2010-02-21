class WorkObserver < ActiveRecord::Observer
  
  # After Create or Update
  def after_save(work)
    #Update any dynamic information about work. This may include:
    #    contributorships, archive state, machine name, scoring hash, etc.
    work.update_work
  end
end
