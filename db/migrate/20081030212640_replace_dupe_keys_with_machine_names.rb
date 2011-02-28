class ReplaceDupeKeysWithMachineNames < ActiveRecord::Migration
  def self.up
   
    # Add Work.machine_name field & add index
    add_column :works, :machine_name, :string
    add_index :works, :machine_name, :name => "work_machine_name"
   
    # Populate the machine_name field for Works
    Work.reset_column_information
    say_with_time "Updating all Works with machine_names..." do
      Work.order('id DESC').all.each do |work|
        # machine name is primary title, downcased, with all punctuation/spaces converted to single space
        machine_name = work.title_primary.chars.gsub(/[\W]+/, " ").strip.downcase
        work.machine_name = machine_name
        work.save
        say "Work with id=#{work.id} updated!", true
      end
    end
    
    # Add Publication.machine_name field & add index
    add_column :publications, :machine_name, :string
    add_index :publications, :machine_name, :name => "publication_machine_name"
    
    # Populate the machine_name field for Publication
    Publication.reset_column_information
    say_with_time "Updating all Publications with machine_names..." do
      Publication.order('id DESC').all.each do |pub|
        # machine name is Publication name, downcased, with all punctuation/spaces converted to single space
        machine_name =  pub.name.chars.gsub(/[\W]+/, " ").strip.downcase
        pub.machine_name = machine_name
        pub.save
        say "Publication with id=#{pub.id} updated!", true
      end
    end
    
    # Add Publisher.machine_name field & add index
    add_column :publishers, :machine_name, :string
    add_index :publishers, :machine_name, :name => "publisher_machine_name"
    
    # Populate the machine_name field for Publisher
    Publisher.reset_column_information
    say_with_time "Updating all Publishers with machine_names..." do
      Publisher.order('id DESC').all.each do |pub|
        # machine name is Publisher name, downcased, with all punctuation/spaces converted to single space
        machine_name =  pub.name.chars.gsub(/[\W]+/, " ").strip.downcase
        pub.machine_name = machine_name
        pub.save_without_callbacks
        say "Publisher with id=#{pub.id} updated!", true
      end
    end
    
    # Add Person.machine_name field & add index
    add_column :people, :machine_name, :string
    add_index :people, :machine_name, :name => "person_machine_name"
   
    # Populate the machine_name field for People
    Person.reset_column_information
    say_with_time "Updating all People with machine_names..." do
      Person.order('id DESC').all.each do |person|
        # machine name is Person name, downcased, with all punctuation/spaces converted to single space
        machine_name =  person.full_name.chars.gsub(/[\W]+/, " ").strip.downcase
        person.machine_name = machine_name
        person.save
        say "Person with id=#{person.id} updated!", true
      end
    end
    
    # Add Group.machine_name field & add index
    add_column :groups, :machine_name, :string
    add_index :groups, :machine_name, :name => "group_machine_name"
   
    # Populate the machine_name field for Groups
    Group.reset_column_information
    say_with_time "Updating all Groups with machine_names..." do
      Group.order('id DESC').all.each do |group|
        # machine name is Group name, downcased, with all punctuation/spaces converted to single space
        machine_name =  group.name.chars.gsub(/[\W]+/, " ").strip.downcase
        group.machine_name = machine_name
        group.save
        say "Group with id=#{group.id} updated!", true
      end
    end
    
    # Add ExternalSystem.machine_name field & add index
    add_column :external_systems, :machine_name, :string
    add_index :external_systems, :machine_name, :name => "external_system_machine_name"
   
    # Populate the machine_name field for ExternalSystems
    ExternalSystem.reset_column_information
    say_with_time "Updating all ExternalSystems with machine_names..." do
      ExternalSystem.order('id DESC').all.each do |system|
        # machine name is Person name, downcased, with all punctuation/spaces converted to single space
        machine_name =  system.name.chars.gsub(/[\W]+/, " ").strip.downcase
        system.machine_name = machine_name
        system.save
        say "ExternalSystem with id=#{system.id} updated!", true
      end
    end
    
    # Drop old dupe_key columns & indices from Works
    remove_column :works, :title_dupe_key
    remove_column :works, :issn_isbn_dupe_key
  end

  def self.down
    # Cannot Return, as the code will no longer support generating old 'dupe keys'
    raise ActiveRecord::IrreversibleMigration
  end
end
