class DropContributorshipTypes < ActiveRecord::Migration
  def self.up
    rename_column :contributorships, :type, :role
  end

  def self.down
    # Don't look back
    raise ActiveRecord::IrreversibleMigration
  end
end
