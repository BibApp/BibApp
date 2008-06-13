class PersonHasManyCitationsRefactor < ActiveRecord::Migration
  def self.up
    rename_table :authors, :author_strings
    remove_column :author_strings, :data_source_id
    remove_column :author_strings, :person_id
    remove_column :author_strings, :authority_id
    rename_column :authorships, :author_id, :person_id
    rename_column :pen_names, :author_id, :author_string_id
  end

  def self.down
    # Don't do it... will archive / reset migrations once this is complete
  end
end
