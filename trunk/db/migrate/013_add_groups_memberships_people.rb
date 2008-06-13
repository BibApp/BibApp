class AddGroupsMembershipsPeople < ActiveRecord::Migration
  def self.up
    create_table "groups", :force => true do |t|
      t.string  :name, :url
      t.timestamps
    end
    
    create_table "memberships", :force => true do |t|
      t.integer :person_id, :group_id
      t.string  :title
      t.boolean :active
      t.timestamps
    end
    
    create_table "people", :force => true do |t|
      t.integer :external_id
      t.string  :first_name, :middle_name, :last_name, :prefix, :suffix
      t.string  :image_url, :phone, :email, :im
      t.string  :office_address_line_one, :office_address_line_two, :office_city, :office_state, :office_zip
      t.text    :research_focus
      t.boolean :active
      t.timestamps
    end
  end

  def self.down
    drop_table :groups
    drop_table :memberships
    drop_table :people
  end
end
