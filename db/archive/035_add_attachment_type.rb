class AddAttachmentType < ActiveRecord::Migration
  def self.up
    add_column :attachments, :type, :string
  end

  def self.down
    # Don't look back
    raise ActiveRecord::IrreversibleMigration
  end
end
