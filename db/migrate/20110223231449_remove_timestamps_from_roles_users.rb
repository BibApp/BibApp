class RemoveTimestampsFromRolesUsers < ActiveRecord::Migration
  def self.up
    change_table :roles_users do |t|
      t.remove :created_at
      t.remove :updated_at
    end
  end

  def self.down
    change_table :roles_users do |t|
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end
end
