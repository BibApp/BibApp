# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111014155047) do

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

  create_table "authentications", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "authentications", ["uid"], :name => "index_authentications_on_uid"
  add_index "authentications", ["user_id"], :name => "index_authentications_on_user_id"

  create_table "contributorship_states", :force => true do |t|
    t.string "name"
  end

  create_table "contributorships", :force => true do |t|
    t.integer  "person_id"
    t.integer  "work_id"
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

  add_index "contributorships", ["work_id", "person_id"], :name => "work_person_join"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "external_system_uris", :force => true do |t|
    t.integer  "external_system_id"
    t.integer  "work_id"
    t.text     "uri"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "external_systems", :force => true do |t|
    t.text     "name"
    t.string   "abbreviation"
    t.text     "base_url"
    t.text     "lookup_params"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "machine_name"
  end

  add_index "external_systems", ["machine_name"], :name => "external_system_machine_name"

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
    t.string   "machine_name"
  end

  add_index "groups", ["machine_name"], :name => "group_machine_name"
  add_index "groups", ["name"], :name => "group_name", :unique => true

  create_table "identifiers", :force => true do |t|
    t.string   "name"
    t.string   "type",       :default => "Unknown", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "identifiers", ["name", "type"], :name => "index_identifiers_on_name_and_type", :unique => true

  create_table "identifyings", :force => true do |t|
    t.integer  "identifier_id",     :null => false
    t.integer  "identifiable_id",   :null => false
    t.string   "identifiable_type", :null => false
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "identifyings", ["identifiable_id", "identifiable_type"], :name => "index_identifyings_on_identifiable_id_and_identifiable_type"
  add_index "identifyings", ["identifier_id"], :name => "index_identifyings_on_identifier_id"

  create_table "imports", :force => true do |t|
    t.integer  "user_id",       :null => false
    t.integer  "person_id"
    t.string   "state"
    t.text     "works_added"
    t.text     "import_errors"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "keywordings", :force => true do |t|
    t.integer  "keyword_id"
    t.integer  "work_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "keywordings", ["work_id", "keyword_id"], :name => "work_keyword_join", :unique => true

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
    t.date     "start_date"
    t.date     "end_date"
  end

  add_index "memberships", ["person_id", "group_id"], :name => "person_group_join"

  create_table "name_strings", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "machine_name"
    t.boolean  "cleaned",      :default => false
  end

  add_index "name_strings", ["machine_name"], :name => "machine_name", :unique => true
  add_index "name_strings", ["name"], :name => "author_name"

  create_table "pen_names", :force => true do |t|
    t.integer  "name_string_id"
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pen_names", ["name_string_id", "person_id"], :name => "author_person_join", :unique => true

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
    t.string   "machine_name"
    t.string   "uid"
    t.string   "display_name"
    t.text     "postal_address"
    t.integer  "user_id"
  end

  add_index "people", ["machine_name"], :name => "person_machine_name"
  add_index "people", ["user_id"], :name => "index_people_on_user_id"

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
    t.string   "machine_name"
    t.integer  "initial_publisher_id"
  end

  add_index "publications", ["authority_id"], :name => "fk_publication_authority_id"
  add_index "publications", ["issn_isbn"], :name => "issn_isbn"
  add_index "publications", ["machine_name"], :name => "publication_machine_name"
  add_index "publications", ["name"], :name => "publication_name"
  add_index "publications", ["publisher_id"], :name => "fk_publication_publisher_id"

  create_table "publisher_sources", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "publishers", :force => true do |t|
    t.integer  "sherpa_id"
    t.integer  "publisher_source_id"
    t.integer  "authority_id"
    t.boolean  "publisher_copy"
    t.string   "name"
    t.string   "url"
    t.string   "romeo_color"
    t.string   "copyright_notice"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "machine_name"
  end

  add_index "publishers", ["authority_id"], :name => "fk_publisher_authority_id"
  add_index "publishers", ["machine_name"], :name => "publisher_machine_name"

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 40
    t.string   "authorizable_type", :limit => 30
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
    t.integer  "user_id"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  add_index "tags", ["name"], :name => "tag_name", :unique => true

  create_table "tolk_locales", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tolk_locales", ["name"], :name => "index_tolk_locales_on_name", :unique => true

  create_table "tolk_phrases", :force => true do |t|
    t.text     "key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tolk_translations", :force => true do |t|
    t.integer  "phrase_id"
    t.integer  "locale_id"
    t.text     "text"
    t.text     "previous_text"
    t.boolean  "primary_updated", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tolk_translations", ["phrase_id", "locale_id"], :name => "index_tolk_translations_on_phrase_id_and_locale_id", :unique => true

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.string   "persistence_token",                       :default => "", :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true

  create_table "work_name_strings", :force => true do |t|
    t.integer  "name_string_id"
    t.integer  "work_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "role"
  end

  add_index "work_name_strings", ["work_id", "name_string_id", "role"], :name => "work_name_string_role_join", :unique => true

  create_table "works", :force => true do |t|
    t.string   "type"
    t.text     "title_primary"
    t.text     "title_secondary"
    t.text     "title_tertiary"
    t.text     "affiliation"
    t.string   "volume"
    t.string   "issue"
    t.string   "start_page"
    t.string   "end_page"
    t.text     "abstract"
    t.text     "notes"
    t.text     "links"
    t.integer  "work_state_id"
    t.integer  "work_archive_state_id"
    t.integer  "publication_id"
    t.integer  "publisher_id"
    t.datetime "archived_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "original_data"
    t.integer  "batch_index",              :default => 0
    t.text     "scoring_hash"
    t.date     "publication_date"
    t.string   "language"
    t.text     "copyright_holder"
    t.boolean  "peer_reviewed"
    t.string   "machine_name"
    t.string   "publication_place"
    t.string   "sponsor"
    t.string   "date_range"
    t.string   "identifier"
    t.string   "medium"
    t.string   "degree_level"
    t.string   "discipline"
    t.string   "instrumentation"
    t.text     "admin_definable"
    t.text     "user_definable"
    t.integer  "authority_publication_id"
    t.integer  "authority_publisher_id"
    t.integer  "initial_publication_id"
    t.integer  "initial_publisher_id"
    t.string   "location"
  end

  add_index "works", ["batch_index"], :name => "batch_index"
  add_index "works", ["machine_name"], :name => "work_machine_name"
  add_index "works", ["publication_id"], :name => "fk_work_publication_id"
  add_index "works", ["publisher_id"], :name => "fk_work_publisher_id"
  add_index "works", ["type"], :name => "fk_work_type"
  add_index "works", ["work_state_id"], :name => "fk_work_state_id"

end
