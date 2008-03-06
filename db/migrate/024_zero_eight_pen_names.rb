class ZeroEightPenNames < ActiveRecord::Migration
  def self.up
    # Rename PenName name_string foreign key for 0.8 release
    rename_column :pen_names, :author_string_id, :name_string_id
  end

  def self.down
    rename_column :pen_names, :name_string_id, :author_string_id
  end
end
