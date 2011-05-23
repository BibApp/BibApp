require 'bundler/capistrano'
require 'tmpdir'

set :production_server, "sophia.cites.illinois.edu"
set :test_server, "athena.cites.illinois.edu"

desc 'Set prerequisites for deployment to production server.'
task :production do
  role :web, production_server
  role :app, production_server
  role :db,  production_server, :primary => true
  before 'deploy:update_code', 'deploy:rsync_ruby'
end

desc 'Set prerequisites for deployment to test(staging) server.'
task :staging do
  role :web, test_server
  role :app, test_server
  role :db,  test_server, :primary => true
  set :branch, 'uiuc-connections-open-id'
end

set :application, "Bibapp"

set :rails_env, ENV['RAILS_ENV'] || 'production'

set :scm, :git
set :repository, 'git://github.com/BibApp/BibApp.git'
set :branch, 'uiuc-connections' unless fetch(:branch, nil)
set :deploy_via, :remote_cache


#directories on the server to deploy the application
#the running instance gets links to [deploy_to]/current
set :home, "/services/ideals-bibapp"
set :deploy_to, "#{home}/bibapp-capistrano"
set :current, "#{deploy_to}/current"
set :shared, "#{deploy_to}/shared"
set :shared_config, "#{shared}/config"
set :public, "#{current}/public"

set :user, 'ideals-bibapp'
set :use_sudo, false

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

  desc "link shared configuration"
  task :link_config do
    ['database.yml', 'ldap.yml', 'personalize.rb', 'smtp.yml', 
     'solr.yml', 'sword.yml', 'oauth.yml', 'open_id.yml'].each do |file|
      run "ln -nfs #{shared_config}/#{file} #{current}/config/#{file}"
    end
  end

  desc "symlink shared subdirectories of public"
  task :symlink_shared_dirs do
    [:attachments, :sherpa].each do |dir|
      run "ln -fs #{public}/system/#{dir} #{public}/#{dir}"
    end
  end

  desc "rsync the ruby directory from the test server to the production server"
  task :rsync_ruby do
    ruby_dir = "/tmp/ruby/"
    bundle_dir = "/tmp/bundle/"
    system "rsync -avPe ssh #{user}@#{test_server}:#{home}/ruby/ #{ruby_dir}"
    system "rsync -avPe ssh #{user}@#{test_server}:#{shared}/bundle/ #{bundle_dir}"
    system "rsync -avPe ssh #{ruby_dir} #{user}@#{production_server}:#{home}/ruby/"
    system "rsync -avPe ssh #{bundle_dir} #{user}@#{production_server}:#{shared}/bundle/"
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

#The sleep is to make sure that solr has enough time to start up before
#running this.
namespace :solr do
  desc "Reindex solr"
  task :refresh_index do
    run "cd #{current}; sleep 10; RAILS_ENV=#{rails_env} rake solr:refresh_index"
  end
end

after 'deploy:setup', 'deploy:create_shared_dirs'

after 'deploy:update', 'deploy:link_config'
after 'deploy:update', 'deploy:symlink_shared_dirs'
before 'deploy:update', 'bibapp:stop'

after 'deploy:start', 'bibapp:start'
after 'deploy:stop', 'bibapp:stop'
after 'deploy:restart', 'bibapp:restart'

after 'bibapp:start', 'solr:refresh_index'
after 'bibapp:restart', 'solr:refresh_index'
