class AddUserIdToPerson < ActiveRecord::Migration

  def self.up
    add_column :people, :user_id, :integer
    add_index :people, :user_id
  end

  def self.down
    remove_index :people, :user_id
    remove_column :people, :user_id
  end
  
end
