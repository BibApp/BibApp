class AddPeerReviewedToCitation < ActiveRecord::Migration
  def self.up    
    # Add peer reviewed flag
    add_column :citations, :peer_reviewed, :boolean    

  end

  def self.down
    # Remove peer reviewed flag
    remove_column :citations, :peer_reviewed
  end
end
