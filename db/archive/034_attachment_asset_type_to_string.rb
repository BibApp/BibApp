class AttachmentAssetTypeToString < ActiveRecord::Migration
  def self.up
    change_column :attachments, :asset_type, :string
  end

  def self.down
    # Don't look back
    raise ActiveRecord::IrreversibleMigration
  end
end
