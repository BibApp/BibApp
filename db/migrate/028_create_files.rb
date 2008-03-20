class CreateFiles < ActiveRecord::Migration
  def self.up
    create_table :files do |t|
      t.integer :citation_id
      t.string :content_type
      t.string :filename  
      t.integer :size
      t.timestamps
    end    
  end

  def self.down
    drop_table :files
  end
end
