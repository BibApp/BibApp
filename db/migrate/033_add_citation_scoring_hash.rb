class AddCitationScoringHash < ActiveRecord::Migration
  def self.up
    add_column :citations, :scoring_hash, :text
  end

  def self.down
    remove_column :citations, :scoring_hash
  end
end
