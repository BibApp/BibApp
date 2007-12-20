class CitationRefactorTwo < ActiveRecord::Migration
  def self.up
    add_column :citations, :serialized_data, :text
    add_column :citations, :original_data, :text
  end

  def self.down
    remove_column :citations, :serialized_data
    remove_column :citations, :original_data
  end
end
