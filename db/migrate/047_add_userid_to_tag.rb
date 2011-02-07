class AddUseridToTag < ActiveRecord::Migration
  def self.up
    add_column :taggings, :user_id, :integer
  end
  
  def self.down
    # Don't look back
    raise ActiveRecord::IrreversibleMigration
  end
end