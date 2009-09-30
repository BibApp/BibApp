class CitationFieldsToText < ActiveRecord::Migration
  def self.up
    
    # Convert most of the varchar[255] into text
    # Keep running into obscure citations that have extra-long data
    change_column :citations, :title_primary, :text
    change_column :citations, :title_secondary, :text
    change_column :citations, :title_tertiary, :text
    change_column :citations, :links, :text
    change_column :citations, :copyright_holder, :text
    
  end

  def self.down
    # Don't look back
    raise ActiveRecord::IrreversibleMigration
  end
end
