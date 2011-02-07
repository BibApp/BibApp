class RemoveWorkStatesTable < ActiveRecord::Migration
  def self.up
    drop_table "work_states"
  end

  def self.down
    create_table "work_states", :force => true do |t|
      t.string "name"
    end
    
    # Re-insert WorkState rows
    WorkState.create(:name => "Processing")
    WorkState.create(:name => "Duplicate")
    WorkState.create(:name => "Accepted")
    WorkState.create(:name => "Incomplete")
    WorkState.create(:name => "Deleted")
  end
end
