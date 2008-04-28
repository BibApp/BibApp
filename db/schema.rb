# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 37) do

  create_table "attachments", :force => true do |t|
    t.string   "filename"
    t.integer  "size"
    t.string   "content_type"
    t.integer  "parent_id"
    t.string   "thumbnail"
    t.integer  "height"
    t.integer  "width"
    t.integer  "asset_id"
    t.string   "asset_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
  end

  create_table "citation_archive_states", :force => true do |t|
    t.string "name"
  end

  create_table "citation_name_strings", :force => true do |t|
    t.integer  "name_string_id"
    t.integer  "citation_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "role"
  end

  create_table "citation_states", :force => true do |t|
    t.string "name"
  end

  create_table "citations", :force => true do |t|
    t.string   "type"
    t.string   "title_primary"
    t.string   "title_secondary"
    t.string   "title_tertiary"
    t.text     "affiliation"
    t.string   "volume"
    t.string   "issue"
    t.string   "start_page"
    t.string   "end_page"
    t.text     "abstract"
    t.text     "notes"
    t.string   "links"
    t.string   "local_archive_uri"
    t.string   "title_dupe_key"
    t.string   "issn_isbn_dupe_key"
    t.integer  "citation_state_id"
    t.integer  "citation_archive_state_id"
    t.integer  "publication_id"
    t.integer  "publisher_id"
    t.datetime "archived_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "original_data"
    t.integer  "batch_index",               :default => 0
    t.text     "scoring_hash"
    t.date     "publication_date"
    t.string   "language"
    t.string   "copyright_holder"
    t.boolean  "peer_reviewed"
  end

  add_index "citations", ["batch_index"], :name => "batch_index"
  add_index "citations", ["publication_id"], :name => "fk_citation_publication_id"
  add_index "citations", ["publisher_id"], :name => "fk_citation_publisher_id"
  add_index "citations", ["citation_state_id"], :name => "fk_citation_state_id"
  add_index "citations", ["type"], :name => "fk_citation_type"
  add_index "citations", ["issn_isbn_dupe_key"], :name => "issn_isbn_dupe"
  add_index "citations", ["title_dupe_key"], :name => "title_dupe"

  create_table "contributorship_states", :force => true do |t|
    t.string "name"
  end

  create_table "contributorships", :force => true do |t|
    t.integer  "person_id"
    t.integer  "citation_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "pen_name_id"
    t.boolean  "highlight"
    t.integer  "score"
    t.boolean  "hide"
    t.integer  "contributorship_state_id"
    t.string   "role"
  end

  add_index "contributorships", ["citation_id", "person_id"], :name => "author_citation_join", :unique => true

  create_table "external_system_keys", :force => true do |t|
    t.integer "external_system_id"
    t.integer "citation_id"
    t.string  "exernal_key_number"
  end

  create_table "external_systems", :force => true do |t|
    t.string "name"
    t.string "abbreviation"
    t.string "base_url"
    t.string "lookup_params"
  end

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.boolean  "hide"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "parent_id"
  end

  add_index "groups", ["name"], :name => "group_name", :unique => true

  create_table "keywordings", :force => true do |t|
    t.integer  "keyword_id"
    t.integer  "citation_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "keywordings", ["citation_id", "keyword_id"], :name => "keyword_citation_join", :unique => true

  create_table "keywords", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "keywords", ["name"], :name => "keyword_name", :unique => true

  create_table "memberships", :force => true do |t|
    t.integer  "person_id"
    t.integer  "group_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
    t.datetime "start_date"
    t.datetime "end_date"
  end

  add_index "memberships", ["group_id", "person_id"], :name => "person_group_join"

  create_table "name_strings", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "name_strings", ["name"], :name => "author_name"

  create_table "pen_names", :force => true do |t|
    t.integer  "name_string_id"
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pen_names", ["person_id", "name_string_id"], :name => "author_person_join", :unique => true

  create_table "people", :force => true do |t|
    t.integer  "external_id"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.string   "prefix"
    t.string   "suffix"
    t.string   "image_url"
    t.string   "phone"
    t.string   "email"
    t.string   "im"
    t.string   "office_address_line_one"
    t.string   "office_address_line_two"
    t.string   "office_city"
    t.string   "office_state"
    t.string   "office_zip"
    t.text     "research_focus"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "scoring_hash"
  end

  create_table "publications", :force => true do |t|
    t.integer  "sherpa_id"
    t.integer  "publisher_id"
    t.integer  "source_id"
    t.integer  "authority_id"
    t.string   "name"
    t.string   "url"
    t.string   "code"
    t.string   "issn_isbn"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "place"
  end

  add_index "publications", ["authority_id"], :name => "fk_publication_authority_id"
  add_index "publications", ["publisher_id"], :name => "fk_publication_publisher_id"
  add_index "publications", ["issn_isbn"], :name => "issn_isbn"
  add_index "publications", ["name"], :name => "publication_name"

  create_table "publisher_sources", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "publishers", :force => true do |t|
    t.integer  "sherpa_id"
    t.integer  "source_id"
    t.integer  "authority_id"
    t.boolean  "publisher_copy"
    t.string   "name"
    t.string   "url"
    t.string   "romeo_color"
    t.string   "copyright_notice"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "publishers", ["authority_id"], :name => "fk_publisher_authority_id"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_type", "taggable_id"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  add_index "tags", ["name"], :name => "tag_name", :unique => true

end
