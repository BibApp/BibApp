class AddPersonIdToAuthors < ActiveRecord::Migration
  def self.up
    add_column :authors, :person_id, :integer
  end

  def self.down
    remove_column :authors, :person_id
  end
end
