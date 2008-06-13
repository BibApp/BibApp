class RolesUsersRemoveId < ActiveRecord::Migration
  def self.up
    # Roles to Users Table is a *JOIN TABLE*
    # In RAILS, that means it shouldn't have an :id column
    # (otherwise HABTM relationships have problems)
    remove_column :roles_users, :id
  end
  
  def self.down
    # Don't look back
    raise ActiveRecord::IrreversibleMigration
  end
end
