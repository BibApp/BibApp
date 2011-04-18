class RenameSourceIdToPublisherSourceIdOnPublishers < ActiveRecord::Migration
  def self.up
    rename_column :publishers, :source_id, :publisher_source_id
  end

  def self.down
    rename_column :publishers, :publisher_source_id, :source_id
  end
end
