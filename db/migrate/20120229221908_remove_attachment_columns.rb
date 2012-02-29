class RemoveAttachmentColumns < ActiveRecord::Migration
  def self.up
    remove_column :attachments, :thumbnail
    remove_column :attachments, :height
    remove_column :attachments, :width
  end

  def self.down
    add_column :attachments, :thumbnail, :string
    add_column :attachments, :height, :integer
    add_column :attachments, :width, :integer
  end
end
