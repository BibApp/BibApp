class AddPersonIdImportedForToCitations < ActiveRecord::Migration
  def self.up
    add_column :citations, :imported_for, :integer
    
    Citation.find(:all, :conditions => "citation_state_id = 3").each do |c|
      au = Authorship.find(:all, :conditions => ["citation_id = ?", c.id], :order => "id ASC", :limit => 1)
      if au.nil?
        #do nothing
      else
        puts "Working on citation #{c.id}"
        puts "Adding #{au[0].person_id}"
        c.update_attribute(:imported_for, au[0].person_id)
      end
    end
  end

  def self.down
    remove_column :citations, :imported_for
  end
end
