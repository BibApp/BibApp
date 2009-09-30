class CreateAuthors < ActiveRecord::Migration
  def self.up
    create_table :authors do |t|
      t.integer :data_source_id
      t.string :name
      t.timestamps 
    end
  end

  def self.down
    drop_table :authors
  end
end
