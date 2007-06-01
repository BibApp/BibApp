class AddPublisherAndPublicationUrlFields < ActiveRecord::Migration
  def self.up
    add_column :publications, :url, :string
    add_column :publishers, :url, :string
  end

  def self.down
    remove_column :publications, :url
    remove_column :publishers, :url
  end
end
