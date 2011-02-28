class RemoveWorkArchiveStatesTable < ActiveRecord::Migration
  def self.up
    drop_table "work_archive_states"
    
    ## Also change state number of "repository record created"
    ## from state 7 to state 3 (since we only have 3 states total now)
    works = Work.all.each do |w|
      if w.work_archive_state_id==7  #old archived state ID
        w.work_archive_state_id=3    #new archived state ID
        w.save
      end
    end
    
  end

  def self.down
    create_table "work_archive_states", :force => true do |t|
      t.string "name"
    end
    
    # Re-insert WorkArchiveState rows
    WorkArchiveState.create(:name => "Not Ready, rights unknown")
    WorkArchiveState.create(:name => "Ready for archiving")
    WorkArchiveState.create(:name => "Archiving is impractical")
    WorkArchiveState.create(:name => "File collected")
    WorkArchiveState.create(:name => "Ready to generate export file for repository")
    WorkArchiveState.create(:name => "Export file has been generated")
    WorkArchiveState.create(:name => "Repository record created, URL known")
    
    ## Change state number of "repository record created"
    ## back to state 7 instead of state 3
    works = Work.all.each do |w|
      if w.work_archive_state_id==3   #new archived state ID
        w.work_archive_state_id=7     #old archived state ID
        w.save
      end
    end
    
  end
end
