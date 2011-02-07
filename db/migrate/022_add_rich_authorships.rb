class AddRichAuthorships < ActiveRecord::Migration
  def self.up
    add_column :authorships, :pen_name_id, :integer
    add_column :authorships, :highlight, :boolean
    add_column :authorships, :score, :integer
    add_column :authorships, :hide, :boolean
  end

  def self.down
    remove_column :authorships, :pen_name_id
    remove_column :authorships, :highlight
    remove_column :authorships, :score
    remove_column :authorships, :hide
  end
end
