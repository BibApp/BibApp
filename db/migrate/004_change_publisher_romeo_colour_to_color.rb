class ChangePublisherRomeoColourToColor < ActiveRecord::Migration
  def self.up
    rename_column :publishers, :romeo_colour, :romeo_color
  end

  def self.down
    rename_column :publishers, :romeo_color, :romeo_colour
  end
end
