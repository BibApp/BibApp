class AddAuthorityIdToAuthors < ActiveRecord::Migration
  def self.up
    add_column :authors, :authority_id, :integer
  end

  def self.down
    remove_column :authors, :authority_id
  end
end
