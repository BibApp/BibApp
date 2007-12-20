class CitationRefactorOne < ActiveRecord::Migration
  def self.up
    rename_column :citations, :citation_archive_handle, :citation_archive_uri
    rename_column :citations, :affiliations, :affiliation
    remove_column :citations, :authors
    remove_column :citations, :keywords
    remove_column :citations, :taggings
    remove_column :citations, :publication_full
    remove_column :citations, :publication_abbreviation
    remove_column :citations, :issn_isbn
    remove_column :citations, :publisher_full
    remove_column :citations, :city_of_publication
    remove_column :citations, :edition
    remove_column :citations, :data_source
    add_column :citations, :data_source_id, :integer
    add_column :citations, :external_id, :integer
  end

  def self.down
    rename_column :citations, :citation_archive_uri, :citation_archive_handle
    rename_column :citations, :affiliation, :affiliations
    add_column :citations, :authors, :string
    add_column :citations, :keywords, :string
    add_column :citations, :taggings, :string
    add_column :citations, :publication_full, :string
    add_column :citations, :publication_abbreviation, :string
    add_column :citations, :issn_isbn, :string
    add_column :citations, :publisher_full, :string
    add_column :citations, :city_of_publication, :string
    add_column :citations, :edition, :string
    add_column :citations, :data_source, :string
    remove_column :citations, :data_source_id
    remove_column :citations, :external_id
  end
end
