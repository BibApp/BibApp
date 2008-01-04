class CreatePenNames < ActiveRecord::Migration
  def self.up
    create_table :pen_names do |t|
      t.integer  :author_id, :person_id
      t.timestamps 
    end
  end

  def self.down
    drop_table :pen_names
  end
end
