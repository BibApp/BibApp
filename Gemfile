source "http://rubygems.org"
source "http://gems.github.com"

#Rails itself
gem "rails", "3.0.4"

#Haml - Haml plugin will fail initialization if haml gem is not installed.
gem "haml"

#Hpricot - used for various HTML parsing purposes
gem "hpricot", "~>0.6"

#HTMLEntities - used to encode UTF-8 data so that it is valid in HTML
gem "htmlentities", "~>4.0.0"

#Daemons - needed to run delayed_job
gem "daemons", "~>1.0.10"

#LibXML Ruby - Dependency of Solr Ruby
#Bundler should take care of it then
gem "libxml-ruby", "~>0.8.3", :require => "xml/libxml"

#Namecase - converts strings to be properly cased
gem "namecase", "~>1.1.0"

#RedCloth - converts plain text or textile to HTML (also used by HAML)
gem "RedCloth",  "~>4.1.9", :require => "redcloth"

#Ruby-Net-LDAP - used to perform LDAP queries
gem "ruby-net-ldap", "~>0.0.4", :require => "net/ldap"

#RubyZip - used to create Zip file to send via SWORD
gem "rubyzip", "~>0.9.1", :require => "zip/zip"

#Solr-Ruby - Solr connections for ruby
gem "solr-ruby", "~>0.0.6", :require => "solr"

#Will Paginate - for fancy pagination
gem 'will_paginate', "~> 3.0.beta", :require => 'will_paginate'

#CMess - Assists with handling parsing citations from a non-Unicode text file
#  See: http://prometheus.rubyforge.org/cmess/
gem 'cmess', "~>0.1.2"

#AASM - Acts as State Machine - helps manage batch import state
gem 'aasm'

#ISBN Tools - Helps validate ISBNs
# See: http://isbn-tools.rubyforge.org/rdoc/index.html
gem 'isbn-tools',  "~>0.1.0", :require => "isbn/tools"

#delayed jobs
gem 'delayed_job'

#data structures
gem 'acts_as_list'
gem 'acts_as_tree', "~> 1.2.3", :git => 'https://github.com/parasew/acts_as_tree.git'

#Change this as appropriate if you are using a different database
#You can also use groups to set it differently for development and
#production, for example. Note that the appropriate database for your
#set up does need to be specified here, though, or things will fail
#pretty quickly.
gem 'pg'

#dump database in YAML form - honestly, I'm not sure why we need this, but
#while I am porting to Rails 3 I'm not going to worry about it.
gem 'yaml_db'

#authorization, replacing plugin used previously
gem 'authorization'

#authentication
gem 'authlogic'
gem 'omniauth'

#batch loading of authors
gem 'fastercsv'

#Adds in some things removed from Rails 3 that are used, including error_messages_for
gem 'dynamic_form'

#For deployment, but can be ignored if not using capistrano
gem 'capistrano'

#include thin webserver for development
#to start it, do 'bundle exec thin start' - this is important, as
#doing simply 'thin start' may pull in unbundled gems and cause
#dependency conflicts
group :development do
  gem 'thin'
end

group :test, :development do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'ruby-debug-base'
  gem 'ruby-debug'
  gem 'ruby-debug-ide'
  gem 'shoulda'
  gem 'factory_girl'
  gem 'rcov'
end
