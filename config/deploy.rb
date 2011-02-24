require 'bundler/capistrano'

set :application, "Bibapp"
set :rails_env, ENV['RAILS_ENV'] || 'production'

#To deploy from one of these repositories, use subversion as the scm
#and uncomment the appropriate repository
set :scm, :subversion
#set :repository,  "http://bibapp.googlecode.com/svn/trunk"
set :repository,  "https://track.library.uiuc.edu/svn/bibapp/trunk"

#To deploy from the GitHub project
#set :scm, :git
#set :repository, "git://github.com/BibApp/BibApp.git"

#directories on the server to deploy the application
#the running instance gets links to [deploy_to]/current
set :deploy_to, "/services/ideals-bibapp/bibapp-capistrano"
set :current, "#{deploy_to}/current"
set :shared, "#{deploy_to}/shared"
set :shared_config, "#{shared}/config"
set :public, "#{current}/public"

set :user, 'ideals-bibapp'
set :use_sudo, false

# Your HTTP server, Apache/etc
role :web, "athena.cites.illinois.edu"
# This may be the same as your `Web` server
role :app, "athena.cites.illinois.edu"
# This is where Rails migrations will run
role :db,  "athena.cites.illinois.edu", :primary => true
#role :db,  "your slave db-server here"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current}/tmp/restart.txt"
  end

  desc "create a config directory under shared"
  task :create_shared_dirs do
    run "mkdir #{shared}/config"
    [:attachments, :groups, :people].each do | dir|
      run "mkdir #{shared}/system/#{dir}"
    end
  end

  desc "copy shared configuration"
  task :copy_config do
    ['database.yml', 'ldap.yml', 'personalize.rb', 'smtp.yml', 
     'solr.yml', 'sword.yml'].each do |file|
      f = "#{shared_config}/#{file}"
      run "[ -e #{f} ] && (cp #{f} #{current}/config/#{file})"
    end
  end

  desc "symlink shared subdirectories of public"
  task :symlink_shared_dirs do
    [:attachments, :groups, :people].each do |dir|
      run "ln -fs #{public}/system/#{dir} #{public}/#{dir}"
    end
  end

end

namespace :bibapp do
  [:stop, :start, :restart].each do |action|
    desc "#{action} Bibapp services" 
    task action do
      begin
        run "cd #{current}; RAILS_ENV=#{rails_env} rake bibapp:#{action}"
      rescue
        puts "Current directory doesn't exist yet"
      end
    end
  end
end

after 'deploy:setup', 'deploy:create_shared_dirs'

after 'deploy:update', 'deploy:copy_config'
after 'deploy:update', 'deploy:symlink_shared_dirs'
before 'deploy:update', 'bibapp:stop'

after 'deploy:start', 'bibapp:start'
after 'deploy:stop', 'bibapp:stop'
after 'deploy:restart', 'bibapp:restart'
