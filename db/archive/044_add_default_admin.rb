class AddDefaultAdmin < ActiveRecord::Migration
  def self.up
    # create an 'admin' user, and assign as System Administrator
    admin = User.create(:login => 'admin',
                :email => 'admin@myu.edu',
                :password => 'bibapp',
                :password_confirmation => 'bibapp')   
    admin.activate            
    admin.roles << Role.create( :name => 'admin', :authorizable_type => 'System')
  end
  
  def self.down
    User.find_by_login("admin").destroy
  end
end
