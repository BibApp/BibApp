class AddBatchIndexToCitations < ActiveRecord::Migration
  def self.up
    add_column :citations, :batch_index, :boolean
  end

  def self.down
    remove_column :citations, :batch_index
  end
end
