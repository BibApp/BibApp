class AddDefaultLocaleToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :default_locale, :string
  end

  def self.down
    remove_column :users, :default_locale
  end
end
