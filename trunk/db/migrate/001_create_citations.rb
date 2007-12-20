class CreateCitations < ActiveRecord::Migration
  def self.up
    create_table :citations do |t|
      t.string  :type
      t.string  :title_primary, :title_secondary, :title_tertiary
      t.string  :authors, :affiliations
      t.string  :keywords, :taggings
      t.string  :publication_full, :publication_abbreviation
      t.string  :year, :volume, :issue, :start_page, :end_page
      t.string  :publisher_full, :city_of_publication
      t.string  :edition
      t.string  :issn_isbn
      t.text    :abstract, :notes
      t.string  :links, :citation_archive_handle
      t.string  :data_source
      t.string  :title_dupe_key, :issn_isbn_dupe_key
      t.integer :citation_state_id, :citation_archive_state_id, :publication_id, :publisher_id, :imported_for, :bump_value
      t.datetime  :archived_at
      t.timestamps 
    end
  end

  def self.down
    drop_table :citations
  end
end
