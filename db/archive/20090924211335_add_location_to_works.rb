class AddLocationToWorks < ActiveRecord::Migration
  def self.up
    add_column :works, :location, :string
  end

  def self.down
    remove_column :works, :location
  end
end
