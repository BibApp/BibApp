class AddBatchIndex < ActiveRecord::Migration
  def self.up
    add_column :citations, :batch_index, :integer, :default => 0
  end

  def self.down
    remove_column :citations, :batch_index
  end
end
