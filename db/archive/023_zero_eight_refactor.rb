class AuthorshipState < ActiveRecord::Base
  has_many :authorships
end

class CitationNameStringType < ActiveRecord::Base
  has_many :citation_name_strings
end

class CitationState < ActiveRecord::Base
  has_many :citations
end

class CitationArchiveState < ActiveRecord::Base
  has_many :citations
end

class ZeroEightRefactor < ActiveRecord::Migration
  def self.up
    # Memberships
    add_column :memberships, :start_date, :datetime
    add_column :memberships, :end_date, :datetime
    remove_column :memberships, :active
    
    # Groups
    add_column :groups, :description, :text
    add_column :groups, :hide, :boolean
    add_column :groups, :start_date, :datetime
    add_column :groups, :end_date, :datetime
    add_column :groups, :parent_id, :integer

    # Authorships
    add_column :authorships, :authorship_state_id, :integer

    # Create AuthorshipStates
    create_table :authorship_states do |t|
      t.string :name
    end
    
    AuthorshipState.create(:name => "Calculated")
    AuthorshipState.create(:name => "Verified")
    AuthorshipState.create(:name => "Denied")
    
    # AuthorStrings becomes NameStrings
    rename_table :author_strings, :name_strings
    
    # CitationAuthorStrings becomes CitationNameStrings
    rename_table :citation_author_strings, :citation_name_strings
    rename_column :citation_name_strings, :author_string_id, :name_string_id
    add_column :citation_name_strings, :citation_name_string_type_id, :integer
    
    # Create CitationNameStringTypes
    # TODO: Add default data (Author, Editor, more...)
    create_table :citation_name_string_types do |t|
      t.string :name
    end
    
    CitationNameStringType.create(:name => "Author")
    CitationNameStringType.create(:name => "Editor")
    
    # Remove unnecessary columns from Citations table
    remove_column :citations, :imported_for
    remove_column :citations, :serialized_data
    remove_column :citations, :bump_value
    remove_column :citations, :data_source_id
    remove_column :citations, :external_id
    rename_column :citations, :citation_archive_uri, :local_archive_uri
    
    # Add CitationStates table
    create_table :citation_states do |t|
      t.string :name
    end
    
    # Insert CitationState rows
    CitationState.create(:name => "Processing")
    CitationState.create(:name => "Duplicate")
    CitationState.create(:name => "Accepted")
    CitationState.create(:name => "Incomplete")
    CitationState.create(:name => "Deleted")
    
    # Add CitationArchiveStates table
    create_table :citation_archive_states do |t|
      t.string :name
    end
    
    CitationArchiveState.create(:name => "Not ready, rights unknown")
    CitationArchiveState.create(:name => "Ready for archiving")
    CitationArchiveState.create(:name => "Archiving is impractical")
    CitationArchiveState.create(:name => "File collected")
    CitationArchiveState.create(:name => "Ready to generate export file for repository")
    CitationArchiveState.create(:name => "Export file has been generated")
    CitationArchiveState.create(:name => "Repository record created, URL known")
        
    # Add ExternalSystems
    create_table :external_systems do |t|
      t.string :name, :abbreviation, :base_url, :lookup_params
    end
    
    # Add ExternalSystemKeys
    create_table :external_system_keys do |t|
      t.integer :external_system_id, :citation_id
      t.string :exernal_key_number
    end
  end

  def self.down
    # Cannot return
  end
end
