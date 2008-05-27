class MembershipsTimestampToDate < ActiveRecord::Migration
  def self.up
    
    # Converts the start_date and end_date fields
    # in the memberships table to date format
    change_column :memberships, :start_date, :date
    change_column :memberships, :end_date, :date
    
  end

  def self.down
    # Don't look back
    raise ActiveRecord::IrreversibleMigration
  end
end
