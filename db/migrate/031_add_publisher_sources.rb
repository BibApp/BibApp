class PublisherSource < ActiveRecord::Base
  has_many :publishers
end

class AddPublisherSources < ActiveRecord::Migration
  def self.up
    create_table :publisher_sources do |t|
        t.string :name
        t.timestamps
    end
    
    PublisherSource.create(:name => "SHERPA")
    PublisherSource.create(:name => "Data import")
  end

  def self.down
    drop_table :publisher_sources
  end
end
