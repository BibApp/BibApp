#We save all the login names to a csv file in tmp keyed on email so that
#this can be reverted as long as that is still present and all the emails are still present
#in the Users table. I see this primarily being useful while I'm still developing this and it'll probably
#come out of the final version.
class RemoveLoginFromUsers < ActiveRecord::Migration

  @@backup_file = File.join(Rails.root, 'tmp', 'user_logins.backup')

  def self.up

    FasterCSV.open(@@backup_file, 'w') do |csv|
      User.all.each do |user|
        csv << [user.email, user.login]
      end
    end
    remove_column :users, :login
  end

  def self.down
    add_column :users, :login, :string
    if File.exists?(@@backup_file)
      user_alist = FasterCSV.read(@@backup_file)
      user_alist.each do |row|
        email, login = *row
        if user = User.find_by_email(email)
          user.login = login
          user.save
        end
      end
    end
  end

end
