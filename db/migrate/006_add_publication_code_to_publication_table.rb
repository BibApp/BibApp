class AddPublicationCodeToPublicationTable < ActiveRecord::Migration
  def self.up
    add_column :publications, :publication_code, :string
  end

  def self.down
    remove_column :publications, :publication_code
  end
end
