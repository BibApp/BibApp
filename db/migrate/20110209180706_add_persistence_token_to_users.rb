class AddPersistenceTokenToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :persistence_token, :string, :null => false, :default => ''
    User.all.each do |u|
      puts "#{u.login}: #{u.persistence_token}"
      u.forget!
      puts "#{u.login}: #{u.persistence_token}"
      puts "#{u.valid?}"
      u.save
      puts "#{u.login}: #{u.persistence_token}"
      u.reload
      puts "#{u.login}: #{u.persistence_token}"      
    end
  end

  def self.down
    remove_column :users, :persistence_token
  end
end
