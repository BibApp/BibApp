class AddIndexesToContributorships < ActiveRecord::Migration
  def self.up
    add_index :contributorships, :person_id
    add_index :contributorships, :contributorship_state_id
  end

  def self.down
    remove_index :contributorships, :contributorship_state_id
    remove_index :contributorships, :person_id
  end
end
