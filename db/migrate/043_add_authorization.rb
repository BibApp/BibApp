class AddAuthorization < ActiveRecord::Migration
  def self.up
   
    # Roles to Users Table
    create_table :roles_users, :force => true, :id => false  do |t|
      t.column :user_id,          :integer
      t.column :role_id,          :integer
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end

    # Roles Table
    create_table :roles, :force => true do |t|
      t.column :name,               :string, :limit => 40
      t.column :authorizable_type,  :string, :limit => 30
      t.column :authorizable_id,    :integer
      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime
    end
    
    
  end
  
  def self.down
    # Drop all tables
    drop_table :roles_users
    drop_table :roles
  end
end
