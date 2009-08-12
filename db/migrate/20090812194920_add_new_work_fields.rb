class AddNewWorkFields < ActiveRecord::Migration
  def self.up
    add_column :works, :publication_place, :string
    add_column :works, :sponsor, :string
    add_column :works, :date_range, :string
    add_column :works, :identifier, :string
    add_column :works, :medium, :string
    add_column :works, :degree_level, :string
    add_column :works, :discipline, :string
    add_column :works, :instrumentation, :string
    add_column :works, :admin_definable, :text
    add_column :works, :user_definable, :text

  end

  def self.down
    remove_column :works, :publication_place
    remove_column :works, :sponsor
    remove_column :works, :date_range
    remove_column :works, :identifier
    remove_column :works, :medium
    remove_column :works, :degree_level
    remove_column :works, :discipline
    remove_column :works, :instrumentation
    remove_column :works, :admin_definable
    remove_column :works, :user_definable
  end
end