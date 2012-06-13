require 'bundler/capistrano'
require 'tmpdir'
require 'fileutils'

set :production_server, "sophia.cites.illinois.edu"
set :test_server, "athena.cites.illinois.edu"
set :new_test_server, "saga-dev.cites.illinois.edu"
set :new_production_server, "saga.cites.illinois.edu"
default_run_options[:shell] = '/bin/bash -l'

desc 'Set prerequisites for deployment to production server.'
task :production do
  role :web, production_server
  role :app, production_server
  role :db, production_server, :primary => true
  before 'deploy:update_code', 'deploy:rsync_ruby'
end

desc 'Set prerequisites for deployment to test(staging) server.'
task :staging do
  role :web, test_server
  role :app, test_server
  role :db, test_server, :primary => true
#  set :branch, 'uiuc-connections-omni-shib'
  set :branch, 'uiuc-connections'
end

task :new_staging do
  role :web, new_test_server
  role :app, new_test_server
  role :db, new_test_server, :primary => true
  set :branch, 'new-uiuc-connections'
end

task :new_production do
  role :web, new_production_server
  role :app, new_production_server
  role :db, new_production_server, :primary => true
  set :branch, 'new-uiuc-connections'
  before 'deploy:update_code', 'deploy:rsync_ruby'
end

#set this if you want to reindex or to redeploy a new copy of the solr installation (e.g. after a schema change)
#e.g. cap staging reindex deploy
task :reindex do
  set :reindex, true
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
set :shared_config, "#{shared_path}/config"
set :public, "#{current_path}/public"

set :user, 'ideals-bibapp'
set :use_sudo, false

namespace :deploy do
  task :start do
    run "cd #{home}/bin ; ./start-bibapp"
  end
  task :stop do
    run "cd #{home}/bin ; ./stop-bibapp"
  end
  task :restart, :roles => :app, :except => {:no_release => true} do
    ;
  end

  desc "create a config directory under shared"
  task :create_shared_dirs do
    run "mkdir #{shared_path}/config"
    [:attachments, :groups, :people].each do |dir|
      run "mkdir #{shared_path}/system/#{dir}"
    end
  end

  desc "link shared configuration"
  task :link_config do
    ['database.yml', 'ldap.yml', 'personalize.rb', 'smtp.yml',
     'solr.yml', 'sword.yml', 'oauth.yml', 'open_id.yml', 'locales.yml', 'keyword_exclusions.yml', 'stopwords.yml'].each do |file|
      run "ln -nfs #{shared_config}/#{file} #{current_path}/config/#{file}"
    end
    run "ln -nfs #{shared_config}/personalize/*.yml #{current_path}/config/locales/personalize/."
  end

  desc "symlink shared subdirectories of public"
  task :symlink_shared_dirs do
    [:attachments, :sherpa].each do |dir|
      run "ln -fs #{public}/system/#{dir} #{public}/#{dir}"
    end
  end

  #Since we can't build on the production server we have to copy the ruby and bundle gems from the test server.
  #Note that this does mean that a lot of stale gems may accumulate over time.
  #For the test server, when we move to the new servers, and assuming that we use rvm, the standard procedure should suffice to clear out
  #gems directly associated with the ruby (clear and rebuild the gemset).
  #For the shared bundle, make sure the latest code is installed and then move the capistrano shared/bundle and run
  #cap staging bundle:install. Assuming that is fine the old bundle can be removed
  #For the production server, you'll have to remove the local cache and also the target directories on the production
  #server. Then run this and everything should be copied over.
  #That said, I think by preserving the local copy, instead of having it in /tmp, should really render weeding the old
  #gems out into an optional activity. (Of course, bundler and rvm help with this as well.)

  desc "rsync the ruby directory from the test server to the production server"
  task :rsync_ruby do
    ruby_dir = "/home/hading/cache/bibapp/ruby/"
    bundle_dir = "/home/hading/cache/bibapp/bundle/"
    system "rsync -avPe ssh #{user}@#{new_test_server}:#{home}/.rvm/ #{ruby_dir}"
    system "rsync -avPe ssh #{user}@#{new_test_server}:#{shared_path}/bundle/ #{bundle_dir}"
    system "rsync -avPe ssh #{ruby_dir} #{user}@#{new_production_server}:#{home}/.rvm/"
    system "rsync -avPe ssh #{bundle_dir} #{user}@#{new_production_server}:#{shared_path}/bundle/"
  end

end

#The sleep is to make sure that solr has enough time to start up before
#running this.
namespace :solr do
  desc "Reindex solr"
  task :refresh_index do
    run "cd #{current_path}; sleep 10; RAILS_ENV=#{rails_env} bundle exec rake solr:refresh_index"
  end

  desc "Copy the index from previous to current release"
  task :copy_index do
    run "rm -rf #{current_release}/vendor/bibapp-solr"
    run "cp -r #{previous_release}/vendor/bibapp-solr #{current_release}/vendor/bibapp-solr"
  end

end

after 'deploy:setup', 'deploy:create_shared_dirs'

after 'deploy:update_code' do
  unless exists?(:reindex)
    find_and_execute_task('solr:copy_index')
  end
end

before 'deploy:create_symlink' do
  run "cd #{home}/bin ; ./stop-bibapp"
end

after 'deploy:create_symlink', 'deploy:link_config'
after 'deploy:create_symlink', 'deploy:symlink_shared_dirs'
after 'deploy:create_symlink' do
  run "cd #{home}/bin ; ./start-bibapp"
end

after 'deploy:start' do
    if exists?(:reindex)
      find_and_execute_task('solr:refresh_index')
    end
end

after 'deploy:restart' do
    if exists?(:reindex)
      find_and_execute_task('solr:refresh_index')
    end
end
