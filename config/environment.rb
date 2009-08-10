# Be sure to restart your server when you modify this file.

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.1.0' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

#############
# Authorization plugin (http://code.google.com/p/rails-authorization-plugin/)
# settings for BibApp's role based access control
# You can override default authorization system constants here.

# Can be 'object roles' (uses Database) or 'hardwired'
AUTHORIZATION_MIXIN = "object roles"

# NOTE : If you use modular controllers like '/admin/products' be sure
# to redirect to something like '/sessions' controller (with a leading slash)
# as shown in the example below or you will not get redirected properly
# 
# This can be set to a hash or to an explicit path like '/login'
#
LOGIN_REQUIRED_REDIRECTION = { :controller => 'sessions', :action => 'new' }
PERMISSION_DENIED_REDIRECTION = { :controller => 'works', :action => 'index' }

# The method your authentication scheme uses to store the location to redirect back to
# For BibApp we use restful_authentication which uses :store_location
STORE_LOCATION_METHOD = :store_location
#############

#Initialize Rails, load all plugins, check gem dependencies, etc.
Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here

  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default all plugins in vendor/plugins are loaded, in alphabetical order
  # :all can be used as a placeholder for all plugins not explicitly named.
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  #################################
  # Gem Dependencies for BibApp
  #   rake gems - to see required application Gems (and which are missing)
  #   rake gems:install - installs any necessary application Gems
  #   rake gems:unpack - unpacks the gems into /vendor/gems/
  #   rake gems:build - builds gems that require local building
  #################################
  #Hpricot - used for various HTML parsing purposes
  config.gem "hpricot", :version=>"~>0.6", :source=>"http://code.whytheluckystiff.net"

  #HTMLEntities - used to encode UTF-8 data so that it is valid in HTML
  config.gem "htmlentities", :version=>"~>4.0.0"
  
  #LibXML Ruby - Dependency of Solr Ruby
  config.gem "libxml-ruby", :lib=>"xml/libxml", :version=>"~>0.8.3"
  
  #Namecase - converts strings to be properly cased
  config.gem "namecase", :version=>"~>1.0.2"
  
  #RedCloth - converts plain text or textile to HTML (also used by HAML)
  config.gem "RedCloth", :lib=>"redcloth", :version=>"~>4.1.9"

  #Ruby-Net-LDAP - used to perform LDAP queries
  config.gem "ruby-net-ldap", :lib=>"net/ldap", :version=>"~>0.0.4"
  
  #RubyZip - used to create Zip file to send via SWORD
  config.gem "rubyzip", :lib=>"zip/zip", :version=>"~>0.9.1"

  #Solr-Ruby - Solr connections for ruby
  config.gem "solr-ruby", :lib=>"solr", :version=>"~>0.0.6"
  
  #Will Paginate - for fancy pagination
  config.gem 'mislav-will_paginate', :lib => 'will_paginate', :version => '~> 2.3.2', :source => 'http://gems.github.com'

  #CMess - Assists with handling parsing citations from a non-Unicode text file
  #  See: http://prometheus.rubyforge.org/cmess/
  config.gem 'cmess', :version=>"~>0.1.2"
  
  #AASM - Acts as State Machine - helps manage batch import state
  config.gem 'rubyist-aasm', :version => '~> 2.0.2', :lib => 'aasm', :source => "http://gems.github.com"
  
  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/models/work_subclasses )
  config.load_paths += %W( #{RAILS_ROOT}/app/models/attachment_subclasses )
  config.load_paths += %W( #{RAILS_ROOT}/app/models/identifier_subclasses )
  config.load_paths += Dir["#{RAILS_ROOT}/vendor/gems/**"].map do |dir| 
    File.directory?(lib = "#{dir}/lib") ? lib : dir
  end


  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  config.action_controller.session = {
    :session_key => '_zoom_session',
    :secret      => '6ef4f4bba39aae6ef1a1da02e1ace6d8'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  config.active_record.observers = :work_observer, :user_observer, 
                                   :group_observer, :person_observer,
                                   :pen_name_observer,
                                   :publication_observer, :publisher_observer,
                                   :index_observer
                                   

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  # See Rails::Configuration for more options

  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory is automatically loaded
end


#Initialize Workling plugin (http://github.com/purzelrakete/workling/)
#  By default, BibApp uses the Spawn plugin (http://rubyforge.org/projects/spawn) 
#  for simple backend processing.
#  However, if you want more scalability/speed, you may want to 
#  switch to using Starling (http://rubyforge.org/projects/starling/)
#  To switch to Starling (UNTESTED)
#    1. Install Starling & startup
#    2. Startup Workling's script/workling_starling_client
#    3. Use this config instead:
#       Workling::Remote.dispatcher = Workling::Remote::Runners::StarlingRunner.new

# Unfortunately, Windows doesn't work consistently with Spawn.  So, we cannot support
# backend processing for Windows.  Poor Windows :(
if RUBY_PLATFORM.include?('mswin32')
  Workling::Remote.dispatcher = Workling::Remote::Runners::NotRemoteRunner.new
else  
  Workling::Remote.dispatcher = Workling::Remote::Runners::SpawnRunner.new
end

