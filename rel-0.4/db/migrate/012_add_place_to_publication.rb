class AddPlaceToPublication < ActiveRecord::Migration
  def self.up
    add_column :publications, :place, :string
  end

  def self.down
    remove_column :publications, :place
  end
end
