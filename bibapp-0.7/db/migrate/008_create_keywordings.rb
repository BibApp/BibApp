class CreateKeywordings < ActiveRecord::Migration
  def self.up
    create_table :keywordings do |t|
      t.integer :keyword_id, :citation_id, :position
      t.timestamps 
    end
  end

  def self.down
    drop_table :keywordings
  end
end
