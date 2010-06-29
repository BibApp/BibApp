class DropPublisherNameIndex < ActiveRecord::Migration
  def self.up
    remove_index :publishers, :name => "publisher_name"
  end

  def self.down
    add_index :publications, [:name], :name => "publisher_name"
  end
end
