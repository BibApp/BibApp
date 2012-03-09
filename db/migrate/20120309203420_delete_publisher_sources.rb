#To the best of my knowledge these receive no real use, so I'm taking them out.
class DeletePublisherSources < ActiveRecord::Migration

  def self.up
    drop_table :publisher_sources
  end

  def self.down
    create_table :publisher_sources do |t|
      t.string :name
      t.timestamps
    end
  end

end
