class CreateInitialStructure < ActiveRecord::Migration
  class ArchiveStatus < ActiveRecord::Base; end
  class CitationState < ActiveRecord::Base; end
  class ReftypeProxy < ActiveRecord::Base; set_table_name "reftypes" ; end

  def self.up
    create_table "archive_statuses", :force => true do |t|
      t.column "name",          :string,  :default => "",    :null => false
      t.column "flags_success", :boolean, :default => false, :null => false
      t.column "flags_failure", :boolean, :default => false, :null => false
    end
  
    ArchiveStatus.create(:name => "Not ready, rights unknown", :flags_success => false, :flags_failure => false)
    ArchiveStatus.create(:name => "Ready for archiving", :flags_success => false, :flags_failure => false)
    ArchiveStatus.create(:name => "Archiving is impractical", :flags_success => false, :flags_failure => false)
    ArchiveStatus.create(:name => "File collected", :flags_success => false, :flags_failure => false)
    ArchiveStatus.create(:name => "Ready to generate export file for repository", :flags_success => false, :flags_failure => false)
    ArchiveStatus.create(:name => "Export file has been generated", :flags_success => false, :flags_failure => false)
    ArchiveStatus.create(:name => "Repository record created, URL known", :flags_success => true, :flags_failure => false)

    create_table "authorships", :force => true do |t|
      t.column "person_id",   :integer,                :null => false
      t.column "citation_id", :integer,                :null => false
      t.column "list_order",  :integer, :default => 0
    end

    add_index "authorships", ["person_id"], :name => "authorships_person_id_index"
    add_index "authorships", ["citation_id"], :name => "authorships_citation_id_index"

    create_table "citation_states", :force => true do |t|
      t.column "name",         :string
      t.column "show_normal",  :boolean
      t.column "show_deleted", :boolean
    end
  
    CitationState.create(:name => "Processing", :show_normal => false, :show_deleted => false)
    CitationState.create(:name => "Duplicate", :show_normal => false, :show_deleted => true)
    CitationState.create(:name => "Deleted", :show_normal => false, :show_deleted => true)
    CitationState.create(:name => "Accepted", :show_normal => true, :show_deleted => false)

    create_table "citations", :force => true do |t|
      t.column "reftype_id",                  :integer,  :limit => 2
      t.column "authors",                     :text
      t.column "affiliations",                :string
      t.column "title_primary",               :string
      t.column "title_secondary",             :string
      t.column "title_tertiary",              :string
      t.column "keywords",                    :string
      t.column "pub_year",                    :integer,  :limit => 4
      t.column "periodical_full",             :string
      t.column "periodical_abbrev",           :string
      t.column "volume",                      :string,   :limit => 50
      t.column "issue",                       :string,   :limit => 50
      t.column "start_page",                  :string,   :limit => 50
      t.column "end_page",                    :string,   :limit => 50
      t.column "edition",                     :string
      t.column "publisher",                   :string
      t.column "place_of_publication",        :string
      t.column "issn_isbn",                   :string
      t.column "availability",                :string
      t.column "author_address_affiliations", :string
      t.column "accession_number",            :string,   :limit => 50
      t.column "language",                    :string,   :limit => 50
      t.column "classification",              :string
      t.column "subfile_database",            :string
      t.column "original_foreign_title",      :string
      t.column "links",                       :string
      t.column "doi",                         :string,   :limit => 100
      t.column "abstract",                    :text
      t.column "notes",                       :text
      t.column "folder",                      :string
      t.column "user_1",                      :string
      t.column "user_2",                      :string
      t.column "user_3",                      :string
      t.column "user_4",                      :string
      t.column "user_5",                      :string
      t.column "call_number",                 :string
      t.column "database_name",               :string
      t.column "data_source",                 :string
      t.column "identifying_phrase",          :string
      t.column "retrieved_date",              :string
      t.column "shortened_title",             :string
      t.column "text_attributes",             :string
      t.column "url",                         :string
      t.column "sponsoring_library",          :string
      t.column "sponsoring_library_location", :string
      t.column "cited_refs",                  :text
      t.column "website_title",               :string
      t.column "website_editor",              :string
      t.column "website_version",             :string
      t.column "pub_date_electronic",         :string
      t.column "source_type",                 :string
      t.column "over_flow",                   :string
      t.column "objects",                     :string
      t.column "citation_state_id",           :integer,                 :default => 1, :null => false
      t.column "title_dupe_key",              :string
      t.column "issn_dupe_key",               :string
      t.column "archive_status_id",           :integer,                 :default => 1, :null => false
      t.column "archive_filename",            :string
      t.column "archived_at",                 :datetime
      t.column "bump_value",                  :integer,                 :default => 0, :null => false
      t.column "publication_id",              :integer
    end

    add_index "citations", ["citation_state_id"], :name => "citations_citation_state_id_index"
    add_index "citations", ["issn_dupe_key"], :name => "citations_issn_dupe_key_index"
    add_index "citations", ["title_dupe_key"], :name => "citations_title_dupe_key_index"
    add_index "citations", ["issn_isbn"], :name => "k_issn_isbn"
    add_index "citations", ["publication_id"], :name => "k_publication_id"

    create_table "feed_states", :force => true do |t|
      t.column "name",          :string
      t.column "flags_success", :boolean, :default => false, :null => false
      t.column "flags_failure", :boolean, :default => false, :null => false
    end

    create_table "feeds", :force => true do |t|
      t.column "person_id",     :integer,                 :null => false
      t.column "title",         :string
      t.column "link",          :string
      t.column "description",   :text
      t.column "pubDate",       :datetime
      t.column "feed_state_id", :integer,  :default => 1, :null => false
    end

    create_table "groups", :force => true do |t|
      t.column "name",       :string
      t.column "suppress",   :boolean,  :default => false, :null => false
      t.column "created_at", :datetime,                    :null => false
    end

    create_table "memberships", :force => true do |t|
      t.column "person_id",  :integer,  :null => false
      t.column "group_id",   :integer,  :null => false
      t.column "title",      :string
      t.column "start_date", :date
      t.column "end_date",   :date
      t.column "created_at", :datetime, :null => false
    end

    create_table "people", :force => true do |t|
      t.column "external_id",      :string
      t.column "first_name",       :string
      t.column "middle_name",      :string
      t.column "last_name",        :string,                  :default => "", :null => false
      t.column "prefix",           :string,   :limit => 50
      t.column "suffix",           :string,   :limit => 50
      t.column "image_url",        :string,   :limit => 200
      t.column "officeaddr_line1", :string
      t.column "officeaddr_line2", :string
      t.column "office_city",      :string
      t.column "office_state",     :string
      t.column "office_zip",       :string
      t.column "office_phone",     :string
      t.column "email_address",    :string
      t.column "created_at",       :datetime
      t.column "updated_at",       :datetime
      t.column "first_last",       :string
    end

    create_table "publications", :force => true do |t|
      t.column "sherpa_id",    :integer
      t.column "issn_isbn",    :string
      t.column "created_at",   :datetime
      t.column "updated_at",   :datetime
      t.column "name",         :string
      t.column "publisher_id", :integer
    end

    add_index "publications", ["issn_isbn"], :name => "issn_isbn", :unique => true

    create_table "publishers", :force => true do |t|
      t.column "sherpa_id",              :integer
      t.column "name",                   :string
      t.column "romeo_color",           :string
      t.column "created_at",             :datetime
      t.column "updated_at",             :datetime
      t.column "dspace_xml",             :text
      t.column "archive_publisher_copy", :boolean,  :default => false, :null => false
    end

    create_table "reftypes", :force => true do |t|
      t.column "refworks_id",      :integer, :null => false
      t.column "refworks_reftype", :string
      t.column "class_name",       :string
    end
  
    ReftypeProxy.create(:refworks_id => 0, :refworks_reftype => "Generic", :class_name => "generic")
    ReftypeProxy.create(:refworks_id => 1, :refworks_reftype => "Journal Article", :class_name => "journal")
    ReftypeProxy.create(:refworks_id => 2, :refworks_reftype => "Abstract", :class_name => "abstract")
    ReftypeProxy.create(:refworks_id => 3, :refworks_reftype => "Book, Whole", :class_name => "book-whole")
    ReftypeProxy.create(:refworks_id => 4, :refworks_reftype => "Book, Section", :class_name => "book-section")
    ReftypeProxy.create(:refworks_id => 5, :refworks_reftype => "Conference Proceeding", :class_name => "conference-proceedings")
    ReftypeProxy.create(:refworks_id => 6, :refworks_reftype => "Patent", :class_name => "patent")
    ReftypeProxy.create(:refworks_id => 7, :refworks_reftype => "Report", :class_name => "report")
    ReftypeProxy.create(:refworks_id => 8, :refworks_reftype => "Monograph", :class_name => "monograph")
    ReftypeProxy.create(:refworks_id => 9, :refworks_reftype => "Dissertation/Thesis", :class_name => "dissertation-thesis")
    ReftypeProxy.create(:refworks_id => 10, :refworks_reftype => "Web Page", :class_name => "web-page")
    ReftypeProxy.create(:refworks_id => 11, :refworks_reftype => "Journal, Electronic", :class_name => "journal-electronic")
    ReftypeProxy.create(:refworks_id => 12, :refworks_reftype => "Newspaper Article", :class_name => "newspaper-article")
    ReftypeProxy.create(:refworks_id => 13, :refworks_reftype => "Book, Edited", :class_name => "book-edited")
    ReftypeProxy.create(:refworks_id => 14, :refworks_reftype => "Dissertation/Thesis, Unpublished", :class_name => "dissertation-thesis-unpublished")
    ReftypeProxy.create(:refworks_id => 15, :refworks_reftype => "Artwork", :class_name => "artwork")
    ReftypeProxy.create(:refworks_id => 16, :refworks_reftype => "Video/DVD", :class_name => "video-dvd")
    ReftypeProxy.create(:refworks_id => 17, :refworks_reftype => "Magazine Article", :class_name => "magazine-article")
    ReftypeProxy.create(:refworks_id => 18, :refworks_reftype => "Map", :class_name => "map")
    ReftypeProxy.create(:refworks_id => 19, :refworks_reftype => "Motion Picture", :class_name => "motion-picture")
    ReftypeProxy.create(:refworks_id => 20, :refworks_reftype => "Music Score", :class_name => "music-score")
    ReftypeProxy.create(:refworks_id => 21, :refworks_reftype => "Sound Recording", :class_name => "sound-recording")
    ReftypeProxy.create(:refworks_id => 22, :refworks_reftype => "Personal Communication", :class_name => "personal-communication")
    ReftypeProxy.create(:refworks_id => 23, :refworks_reftype => "Grant", :class_name => "grant")
    ReftypeProxy.create(:refworks_id => 24, :refworks_reftype => "Unpublished Material", :class_name => "unpublished-material")
    ReftypeProxy.create(:refworks_id => 25, :refworks_reftype => "Online Discussion Forum", :class_name => "online-disscussion-forum")
    ReftypeProxy.create(:refworks_id => 26, :refworks_reftype => "Case/Court Decisions", :class_name => "case-court-decisions")
    ReftypeProxy.create(:refworks_id => 27, :refworks_reftype => "Hearing", :class_name => "hearing")
    ReftypeProxy.create(:refworks_id => 28, :refworks_reftype => "Laws/Statutes", :class_name => "laws-statutes")
    ReftypeProxy.create(:refworks_id => 29, :refworks_reftype => "Bills/Resolutions", :class_name => "bills-resolutions")
    ReftypeProxy.create(:refworks_id => 30, :refworks_reftype => "Computer Program", :class_name => "computer-program")

    create_table "sessions", :force => true do |t|
      t.column "session_id", :string
      t.column "data",       :text
      t.column "updated_at", :datetime
    end

    add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
    add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

    create_table "taggings", :force => true do |t|
      t.column "tag_id",        :integer
      t.column "taggable_id",   :integer
      t.column "taggable_type", :string
    end

    add_index "taggings", ["taggable_id"], :name => "taggings_taggable_id_index"

    create_table "tags", :force => true do |t|
      t.column "name", :string
    end

    add_index "tags", ["name"], :name => "tags_name_index"

    create_table "users", :force => true do |t|
      t.column "login",            :string
      t.column "email",            :string
      t.column "crypted_password", :string,   :limit => 40
      t.column "salt",             :string,   :limit => 40
      t.column "created_at",       :datetime
      t.column "updated_at",       :datetime
    end
  end
  
  def self.down
    drop_table :archive_statuses
    drop_table :authorships
    drop_table :citation_states
    drop_table :citations
    drop_table :feed_states
    drop_table :feeds
    drop_table :groups
    drop_table :memberships
    drop_table :people
    drop_table :publications
    drop_table :publishers
    drop_table :reftypes
    drop_table :sessions
    drop_table :taggings
    drop_table :tags
    drop_table :users
  end
end
