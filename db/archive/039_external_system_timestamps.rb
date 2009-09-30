class ExternalSystemTimestamps < ActiveRecord::Migration
  def self.up
    
    # add timestamps to External Systems
    add_column :external_systems, :created_at, :datetime
    add_column :external_systems, :updated_at, :datetime
    
    # add timestamps to External System URIs
    add_column :external_system_uris, :created_at, :datetime
    add_column :external_system_uris, :updated_at, :datetime
    
  end

  def self.down
    # Don't look back
    raise ActiveRecord::IrreversibleMigration
  end
end
