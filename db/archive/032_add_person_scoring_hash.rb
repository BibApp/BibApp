class AddPersonScoringHash < ActiveRecord::Migration
  def self.up
    add_column :people, :scoring_hash, :text
  end

  def self.down
    remove_column :people, :scoring_hash
  end
end
