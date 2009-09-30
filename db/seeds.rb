
puts "\nCreating admin user...\n"
# create an 'admin' user, and assign as System Administrator
dupe = User.find_by_login('admin')
if dupe.nil?
  admin = User.create(:login => 'admin',
              :email => 'admin@myu.edu',
              :password => 'bibapp',
              :password_confirmation => 'bibapp')
  admin.activate
  admin.roles << Role.create( :name => 'admin', :authorizable_type => 'System')
else
  puts "Error: admin user already exists"
end

puts "\nUpdating all SHERPA/RoMEO data in BibApp...\n"

#Call update_sherpa_data, which re-indexes *everything* in BibApp
Publisher.update_sherpa_data

puts "\nFinished! Log in with user 'admin' and password 'bibapp'."
