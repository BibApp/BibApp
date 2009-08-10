class PenNameObserver < ActiveRecord::Observer

  # PenName Notes:
  # 1. Person has a new PenName
  # * Create a Contributorship row for each unique Work associated with PenName
  # * Set Contributorship.score to calculated (options: calculated (0), verified (1), denied (2))
  #
  # 2. More than one Person claims same PenName
  # * Add Contributorship row, as described above
  # * Maybe use the contributorship.hide column? But it doesn't feel right today...
  # * @TODO Create a "contributorships/admin?view=duplicate_claims"
  
  
  
  # Anytime a Person claims a PenName, we need to do several things:
  #  1. Create a Contributorship row for each unique Work associated with PenName
  #  2. Re-index all those associated Works in Solr
  def after_save(pen_name)
    
    # create new contributorships
    contributorships = set_contributorships(pen_name)
   
    #Asynchronously update Solr index for affected Works
    #  (This uses the Workling Plugin for asynchronization)
    works = contributorships.collect{|contrib| contrib.work}
    Index.send_later(:batch_update_solr, works)
  end
  
  # Anytime a PenName is removed, we need to do the following:
  # 1. Re-index all Works associated with that PenName in Solr
  # 2. Remove all related Contributorship rows
  def before_destroy(pen_name)
    #find all contributorships associated with PenName
    contributorships = find_contributorships(pen_name)
    
    #Asynchronously update Solr index for affected Works
    works = contributorships.collect{|contrib| contrib.work}
    Index.send_later(:batch_update_solr, works)
    
    #Finally, destroy all these contributorships
    contributorships.each{|c| c.destroy}
  end
  
  # Create a Contributorship row for each unique Work associated with PenName
  #   Returns a list of contributorships created
  def set_contributorships(pen_name)
    contributorships = Array.new
    pen_name.name_string.work_name_strings.each do |cns|
      #only create Contributorship for "accepted" works
      if cns.work.accepted?
        contributorships << Contributorship.find_or_create_by_work_id_and_person_id_and_pen_name_id_and_role(
            cns.work.id, 
            pen_name.person_id, 
            pen_name.id,
            cns.role
          )
      end
    end
    return contributorships
  end
  
  # Find all Contributorships associated with this PenName
  def find_contributorships(pen_name)
    contributorships = Contributorship.find(
        :all, 
        :conditions => ["pen_name_id = ? and person_id = ?", pen_name.id, pen_name.person_id]
      )
    return contributorships
  end
end
