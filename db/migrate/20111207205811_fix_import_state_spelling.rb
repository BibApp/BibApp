class FixImportStateSpelling < ActiveRecord::Migration
  def self.up
    Import.where(:state => 'recieved').update_all(:state => 'received')
  end

  def self.down
    Import.where(:state => 'received').update_all(:state => 'recieved')
  end
end
