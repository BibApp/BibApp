class CreatePublisherSources < ActiveRecord::Migration
  def self.up
    create_table :publisher_sources do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :publisher_sources
  end
end
