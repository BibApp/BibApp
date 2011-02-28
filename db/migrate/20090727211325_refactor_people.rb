class RefactorPeople < ActiveRecord::Migration
  def self.up
    
    add_column :people, :uid, :string
    add_column :people, :display_name, :string
    add_column :people, :postal_address, :text

    #Copy email name into UID
    say_with_time "Creating UID from email address..." do
      Person.all.each do |p|
        p.update_attribute(:uid, p.email.split("@")[0])
        say "Person #{p.uid} updated!", true
      end
    end

    #Create display name
    say_with_time "Creating display name..." do
      Person.all.each do |p|
        fn = p.first_name.nil? || p.first_name=="" ? "" : p.first_name + " "
        mn = p.middle_name.nil? || p.middle_name=="" ? "" : p.middle_name + " "
        ln = p.last_name.nil? || p.last_name=="" ? "" : p.last_name + " "
        sx = p.suffix.nil? || p.suffix=="" ? "" : p.suffix + " "
        p.update_attribute(:display_name, fn + mn + ln + sx)
        say "Person #{p.display_name} updated!", true
      end
    end

    #Create postal address
    say_with_time "Creating postal address..." do
      Person.all.each do |p|
        oa1 = p.office_address_line_one.nil? || p.office_address_line_one=="" ? "" : p.office_address_line_one + "\n"
        oa2 = p.office_address_line_two.nil? || p.office_address_line_two=="" ? "" : p.office_address_line_two + "\n"
        oc = p.office_city.nil? || p.office_city=="" ? "" : p.office_city + "\n"
        os = p.office_state.nil? || p.office_state=="" ? "" : p.office_state + "\n"
        oz = p.office_zip.nil? || p.office_zip=="" ? "" : p.office_zip + "\n"
        p.update_attribute(:postal_address, oa1 + oa2 + oc + os + oz)
        say "Person #{p.display_name} updated!", true
      end
    end
  end

  def self.down
    remove_column :people, :uid
    remove_column :people, :display_name
    remove_column :people, :postal_address
  end
end
