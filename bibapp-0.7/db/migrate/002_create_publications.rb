class CreatePublications < ActiveRecord::Migration
  def self.up    
    create_table "publications", :force => true do |t|
      t.integer :sherpa_id, :publisher_id, :source_id, :authority_id
      t.string  :name, :url, :code, :issn_isbn
      t.timestamps
    end
    
    create_table "publishers", :force => true do |t|
      t.integer :sherpa_id, :source_id, :authority_id
      t.boolean :publisher_copy
      t.string  :name, :url, :romeo_color, :copyright_notice
      t.timestamps
    end
  end

  def self.down
    drop_table :publications
    drop_table :publishers
  end
end
