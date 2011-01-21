class CreateCitationAuthorStrings < ActiveRecord::Migration
  def self.up
    create_table :citation_author_strings do |t|
      t.integer :author_string_id, :citation_id, :position
      t.timestamps
    end
  end

  def self.down
    drop_table :citation_author_strings
  end
end
