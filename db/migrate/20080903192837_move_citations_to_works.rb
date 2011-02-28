class MoveCitationsToWorks < ActiveRecord::Migration
  def self.up

    # Important -- Order is extremely meaningful here
    # 1) Remove indexes
    # 2) Rename columns
    # 3) Rename table
    # 4) Add indexes
    # 5) Repeat
    
    # Attachments
    # Update attachments set asset_type = "Work" where asset_type = "Citation"
    Attachment.all.each do |a|
      if a.asset_type == "Citation"
        a.asset_type = "Work"
        a.save
      end
    end
    
    # Citations => Works
    remove_index(:citations, :name => "fk_citation_publication_id")
    remove_index(:citations, :name => "fk_citation_publisher_id")
    remove_index(:citations, :name => "fk_citation_state_id")
    remove_index(:citations, :name => "fk_citation_type")
        
    rename_column(:citations, :citation_state_id, :work_state_id)
    rename_column(:citations, :citation_archive_state_id, :work_archive_state_id)
    rename_table(:citations, :works)
    
    add_index(:works, [:publication_id],:name => "fk_work_publication_id")
    add_index(:works, [:publisher_id],  :name => "fk_work_publisher_id")
    add_index(:works, [:work_state_id], :name => "fk_work_state_id")
    add_index(:works, [:type],          :name => "fk_work_type")
    
    # CitationArchiveStates => WorkArchiveStates
    rename_table(:citation_archive_states, :work_archive_states)
    
    # CitationNameStrings => WorkNameStrings
    #remove_index(:citation_name_strings, :name => "citation_name_string_join")
    
    rename_column(:citation_name_strings, :citation_id, :work_id)
    rename_table(:citation_name_strings, :work_name_strings)
    
    add_index(:work_name_strings, [:work_id, :name_string_id], :name => "work_name_string_join", :unique => true)
    
    # CitationStates => WorkStates
    rename_table(:citation_states, :work_states)
    
    # Contributorships
    remove_index(:contributorships, :name => "author_citation_join")
    
    rename_column(:contributorships, :citation_id, :work_id)
    
    add_index(:contributorships, [:work_id, :person_id], :name => "work_person_join")
    
    # ExternalSystemURIs
    rename_column(:external_system_uris, :citation_id, :work_id)
    
    # Keywordings
    remove_index(:keywordings, :name => "keyword_citation_join")
    
    rename_column(:keywordings, :citation_id, :work_id)
    
    add_index(:keywordings, [:work_id, :keyword_id], :name => "work_keyword_join", :unique => true)
    
    # Taggings
    # Update taggings set taggable_type = "Work" where taggable_type = "Citation"
    Tagging.all.each do |t|
      if t.taggable_type == "Citation"
        t.taggable_type = "Work"
        t.save
      end
    end
  end

  def self.down
    # Attachments
    # Update attachments set asset_type = "Citation" where asset_type = "Work"
    Attachment.all.each do |a|
      if a.asset_type == "Work"
        a.asset_type = "Citation"
        a.save
      end
    end
    
    # Contributorships
    remove_index(:contributorships, :name => "work_person_join")

    rename_column(:contributorships, :work_id, :citation_id)

    add_index(:contributorships, [:citation_id, :person_id], :name => "author_citation_join")
    
    # ExternalSystemURIs
    rename_column(:external_system_uris, :work_id, :citation_id)
    
    # Keywordings
    remove_index(:keywordings, :name => "work_keyword_join")
    
    rename_column(:keywordings, :work_id, :citation_id)
    
    add_index(:keywordings, [:citation_id, :keyword_id], :name => "keyword_citation_join", :unique => true)
    
    # Works => Citations
    remove_index(:works, :name => "fk_work_publication_id")
    remove_index(:works, :name => "fk_work_publisher_id")
    remove_index(:works, :name => "fk_work_state_id")
    remove_index(:works, :name => "fk_work_type")
    
    rename_column(:works, :work_state_id, :citation_state_id)
    rename_column(:works, :work_archive_state_id, :citation_archive_state_id)
    rename_table(:works, :citations)
    
    add_index(:citations, [:publication_id],    :name => "fk_citation_publication_id")
    add_index(:citations, [:publisher_id],      :name => "fk_citation_publisher_id")
    add_index(:citations, [:citation_state_id], :name => "fk_citation_state_id")
    add_index(:citations, [:type],              :name => "fk_citation_type")

    # WorkArchiveStates => CitationArchiveStates
    rename_table(:work_archive_states, :citation_archive_states)
    
    # WorkNameStrings => CitationNameStrings
    remove_index(:work_name_strings, :name => "work_name_string_join")
    
    rename_column(:work_name_strings, :work_id, :citation_id)
    rename_table(:work_name_strings, :citation_name_strings)
    
    add_index(:citation_name_strings, [:citation_id, :name_string_id], :name => "citation_name_string_join", :unique => true)

    # WorkStates => CitationStates
    rename_table(:work_states, :citation_states)
    
    # Taggings
    # Update taggings set taggable_type = "Citation" where asset_type = "Work"
    Tagging.all.each do |t|
      if t.asset_type == "Work"
        t.asset_type = "Citation"
        t.save
      end
    end
  end
end