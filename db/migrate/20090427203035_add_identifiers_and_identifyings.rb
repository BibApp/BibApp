class AddIdentifiersAndIdentifyings < ActiveRecord::Migration
  def self.up
    create_table :identifiers do |t|
      t.string :name
      t.string :type, :null => false, :default => "Unknown"
      t.timestamps 
    end
    
    add_index "identifiers", ["name", "type"], :name => "index_identifiers_on_name_and_type", :unique => true
    
    create_table :identifyings do |t|
      t.integer :identifier_id,     :null => false
      t.integer :identifiable_id,   :null => false
      t.string  :identifiable_type, :null => false
      t.integer :position
      t.timestamps 
    end
    
    add_index "identifyings", ["identifier_id"], :name => "index_identifyings_on_identifier_id"
    add_index "identifyings", ["identifiable_id", "identifiable_type"], :name => "index_identifyings_on_identifiable_id_and_identifiable_type"
  end

  def self.down
    drop_table :identifiers
    drop_table :identifyings
  end
end
