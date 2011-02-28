class AddMachineNameToNameStrings < ActiveRecord::Migration
  def self.up    
    # Add name_string.machine_name field
    add_column :name_strings, :machine_name, :string

    # Add name_string.cleaned? field to see if data has been cleaned 
    add_column :name_strings, :cleaned, :boolean, :default => false
    
    # Populate the machine_name field
    NameString.reset_column_information
    name_strings = NameString.all

    name_strings.each do |ns|
      # Set the machine_name version of the name field
      ns.machine_name = ns.name.gsub(".", " ").gsub(",", " ").gsub(/ +/, " ").strip.downcase

      # Reset the name field, based on the machine_name version and save
      ns.set_name
    end
    
    # Find all duplicate machine_names and their ids
    puts "Finding all duplicates"
    duplicates = NameString.find_by_sql(
      "SELECT n1.id, n1.machine_name FROM name_strings n1
      join name_strings n2 on n2.machine_name = n1.machine_name
      where n1.id != n2.id
      order by machine_name"
    )
    puts "Duplicates: #{duplicates.size}"
    
    # Array of duplicate machine_names
    duplicates = duplicates.collect{|ns| ns.machine_name}.uniq
    
    # For each duplicate machine name
    # 1) Find all duplicates
    # 2) Select first candidate as keeper
    # 3) All other candidates are dupes - we'll remove then...
    # 4) Associate dupe citation_name_strings with keeper.id
    # 5) Delete duplicate
    
    puts "Unique duplicate names: #{duplicates.size}"
    duplicates.each do |dupe|
      puts "Cleaning: #{dupe}"
      # Find all duplicates
      dupe_candidates = NameString.where(:machine_name => dupe).all
      puts "Count for #{dupe}: #{dupe_candidates.size}"
      
      # Clean them up - first is keeper, rest are dupes
      count = 0
      dupe_candidates.each do |dc|
        count = count + 1
        # Select the first candidate as keeper (cleaned = true)
        if count == 1
          puts "Keeper: #{dc.id}"
          dc.update_attribute(:cleaned, true)
        else
          # All other candidates are dupes (cleaned = false)
          citation_name_strings = CitationNameString.find_by_sql("select * from citation_name_strings where name_string_id = #{dc.id}")
          citation_name_strings.each{ |cns|
            puts "Reassociating: #{dc.id}"
            cns.update_attribute(:name_string_id, dupe_candidates[0].id)
          }
          
          #Refresh our dupe candidate, so we can check if it now has no citation_name_strings
          dc.reload
          citation_name_strings = CitationNameString.find_by_sql("select * from citation_name_strings where name_string_id = #{dc.id}")
          
          if citation_name_strings.empty?
            # Destroy the dupe
            puts "Destroying NameString: #{dc.id}"
            dc.destroy
          else
            puts "Trouble cleaning NameString: #{dc.id} It still has #{citation_name_strings.size} CitationNameStrings associated."
          end
        end
      end
    end
    
    # Return all NameStrings to ready state (cleaned = false)
    # People can use this flag to make manual edits to NameStrings
    name_strings = NameString.all
    name_strings.each{|ns| ns.update_attribute(:cleaned, false)}

    # Set unique index on machine_name
    add_index :name_strings, :machine_name, :unique => true, :name => "machine_name"
  end

  def self.down
    # Remove machine_name index
    remove_index :name_strings, :machine_name
    
    # Remove machine_name field
    remove_column :name_strings, :machine_name
    remove_column :name_strings, :cleaned
  end
  
  
  #Placeholder class, since this no longer exists in our model
  # The addition of this class allows us to still interact with the citation_name_strings
  # table, even though we've since removed it from BibApp.  It also ensures that folks
  # can upgrade from BibApp 0.7 -> 1.0 without migration issues.
  class CitationNameString < ActiveRecord::Base
  end
end
