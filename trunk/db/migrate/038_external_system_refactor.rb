class ExternalSystemRefactor < ActiveRecord::Migration
  def self.up
    
    #rename external_systems_key table
    rename_table :external_system_keys, :external_system_uris
    
    #rename badly named/misspelled column 'exernal_key_number'
    rename_column :external_system_uris, :exernal_key_number, :uri   
    change_column :external_system_uris, :uri, :text

    #wipe out the old "local_archive_uri" column, which is obsolete now
    remove_column :citations, :local_archive_uri
    
    #change :external_systems columns to 'text'
    change_column :external_systems, :name, :text
    change_column :external_systems, :base_url, :text
    change_column :external_systems, :lookup_params, :text
  end

  def self.down
    # Don't look back
    raise ActiveRecord::IrreversibleMigration
  end
end
