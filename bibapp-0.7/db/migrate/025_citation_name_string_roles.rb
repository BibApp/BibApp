class CitationNameStringRoles < ActiveRecord::Migration
  def self.up
    drop_table :citation_name_string_types
    remove_column :citation_name_strings, :citation_name_string_type_id
    add_column :citation_name_strings, :role, :string
  end

  def self.down
    # Do Not Return!
  end
end
