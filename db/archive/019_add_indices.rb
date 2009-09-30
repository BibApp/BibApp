class AddIndices < ActiveRecord::Migration
  def self.up
    add_index :authors, [:name], :name => "author_name"
    add_index :authors, [:person_id], :name => "fk_author_person_id"
    add_index :authorships, [:author_id, :citation_id], :name => "author_citation_join", :unique => true
    add_index :citations, [:title_dupe_key], :name => "title_dupe"
    add_index :citations, [:issn_isbn_dupe_key], :name => "issn_isbn_dupe"
    add_index :citations, [:citation_state_id], :name => "fk_citation_state_id"
    add_index :citations, [:publication_id], :name => "fk_citation_publication_id"
    add_index :citations, [:publisher_id], :name => "fk_citation_publisher_id"
    add_index :citations, [:batch_index], :name => "batch_index"
    add_index :citations, [:type], :name => "fk_citation_type"
    add_index :groups, [:name], :name => "group_name", :unique => true
    add_index :keywordings, [:keyword_id, :citation_id], :name => "keyword_citation_join", :unique => true
    add_index :keywords, [:name], :name => "keyword_name", :unique => true
    add_index :memberships, [:person_id, :group_id], :name => "person_group_join"
    add_index :pen_names, [:author_id, :person_id], :name => "author_person_join", :unique => true
    add_index :publications, [:publisher_id], :name => "fk_publication_publisher_id"
    add_index :publications, [:authority_id], :name => "fk_publication_authority_id"
    add_index :publications, [:name], :name => "publication_name"
    add_index :publications, [:issn_isbn], :name => "issn_isbn"
    add_index :publishers, [:name], :name => "publisher_name", :unique => true
    add_index :publishers, [:authority_id], :name => "fk_publisher_authority_id"
    add_index :tags, [:name], :name => "tag_name", :unique => true
  end

  def self.down
    remove_index :authors, :name => :author_name
    remove_index :authors, :name => :fk_author_person_id
    remove_index :authorships, :name => :author_citation_join
    remove_index :citations, :name => :title_dupe
    remove_index :citations, :name => :issn_isbn_dupe
    remove_index :citations, :name => :fk_citation_state_id
    remove_index :citations, :name => :fk_citation_publication_id
    remove_index :citations, :name => :fk_citation_publisher_id
    remove_index :citations, :name => :batch_index
    remove_index :citations, :name => :fk_citation_type
    remove_index :groups, :name => :group_name
    remove_index :keywordings, :name => :keyword_citation_join
    remove_index :keywords, :name => :keyword_name
    remove_index :memberships, :name => :person_group_join
    remove_index :pen_names, :name => :author_person_join
    remove_index :publications, :name => :fk_publication_publisher_id
    remove_index :publications, :name => :fk_publication_authority_id
    remove_index :publications, :name => :publication_name
    remove_index :publications, :name => :issn_isbn
    remove_index :publishers, :name => :publisher_name
    remove_index :publishers, :name => :fk_publisher_authority_id
    remove_index :tags, :name => :tag_name
  end
end
