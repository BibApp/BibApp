class CreateImports < ActiveRecord::Migration
  def self.up
    create_table :imports do |t|
      t.integer :user_id, :null => false
      t.integer :person_id
      t.string  :state
      t.text    :works_added
      t.text    :errors
      t.timestamps
    end
  end

  def self.down
    drop_table :imports
  end
end