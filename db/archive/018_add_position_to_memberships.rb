class AddPositionToMemberships < ActiveRecord::Migration
  def self.up
    add_column :memberships, :position, :integer
  end

  def self.down
    remove_column :memberships, :position
  end
end
