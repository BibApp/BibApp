#####################################
# Initialize Solr Settings for BibApp
#
# Note: Any of the below variables can
# be overridden in your environment.rb
# or environment/production.rb if
# you need custom Solr settings
#####################################
#Require Solr, if it's defined.  
# This allows us to make solr-ruby a Gem Dependency, as suggested in this blog:
# http://www.webficient.com/2008/7/11/rails-gem-dependencies-and-plugin-errors
require 'solr' if defined? Solr

# Solr Path (in /vendor/solr by default)
SOLR_PATH = "#{File.dirname(__FILE__)}/../../vendor/solr" unless defined? SOLR_PATH

# Solr Home Path (in /vendor/bibapp-solr by default)
SOLR_HOME_PATH = "#{File.dirname(__FILE__)}/../../vendor/bibapp-solr" unless defined? SOLR_HOME_PATH

# Solr Java Options (used to give Solr more memory, etc.)
#  Default: give 256MB of memory to start, with 512MB memory maximum
SOLR_JAVA_OPTS = "-Xms256M -Xmx512M"  unless defined? SOLR_JAVA_OPTS

# Solr Config (in /config/solr.yml)
SOLR_CONFIG = "#{File.dirname(__FILE__)}/../../config/solr.yml" unless defined? SOLR_CONFIG

# Load our Solr Configuration (from solr.yml) for our current environment
SOLR_SETTINGS = YAML::load(File.read(SOLR_CONFIG))[Rails.env] if File.exists?(SOLR_CONFIG)

# Set Solr port (default to port 8983 if no port found in solr.yml)
# (This SOLR_PORT variable is used by /lib/tasks/solr.rake when starting Solr)
SOLR_PORT = SOLR_SETTINGS['port'] if SOLR_SETTINGS and SOLR_SETTINGS['port']
SOLR_PORT = "8983" unless defined? SOLR_PORT

# Port used to send "stop" command to Jetty in order to shutdown Solr nicely
# (This SOLR_STOP_PORT variable is used by /lib/tasks/solr.rake when stopping Solr)
SOLR_STOP_PORT = SOLR_SETTINGS['stop_port'] if SOLR_SETTINGS and SOLR_SETTINGS['stop_port']
SOLR_STOP_PORT = "8097" unless defined? SOLR_STOP_PORT

# Build our Solr URL (used by Solr Connection below)
SOLR_URL = "http://127.0.0.1:#{SOLR_PORT}/solr" unless defined? SOLR_URL

# Solr Connection (used by /app/models/index.rb)
SOLRCONN = Solr::Connection.new(SOLR_URL)