class MoveToContributorships < ActiveRecord::Migration
  def self.up
    rename_table :authorship_states, :contributorship_states
    rename_table :authorships, :contributorships
    rename_column :contributorships, :authorship_state_id, :contributorship_state_id
    add_column :contributorships, :type, :string
  end

  def self.down
    # Don't look back
    raise ActiveRecord::IrreversibleMigration
  end
end
