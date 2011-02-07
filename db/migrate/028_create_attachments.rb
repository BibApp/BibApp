class CreateAttachments < ActiveRecord::Migration
  def self.up
    create_table :attachments do |t|
      #attachment_fu required columns
      t.string :filename  
      t.integer :size
      t.string :content_type
      #attachment_fu image-based columns
      t.integer :parent_id
      t.string :thumbnail
      t.integer :height
      t.integer :width
      
      #polymorphic association
      t.integer :asset_id
      t.integer :asset_type
      
      t.timestamps
    end    
  end

  def self.down
    drop_table :attachments
  end
end
