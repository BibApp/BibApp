class SetGroupsHideFalse < ActiveRecord::Migration
  def self.up
    execute "UPDATE groups SET hide = false"
  end
  
  def self.down
    # Don't look back
    raise ActiveRecord::IrreversibleMigration
  end
end