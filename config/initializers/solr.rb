# Solr Path (in /vendor/solr)
SOLR_PATH = "#{File.dirname(__FILE__)}/../../vendor/solr" unless defined? SOLR_PATH

# Solr Config (in /config/solr.yml)
SOLR_CONFIG = "#{File.dirname(__FILE__)}/../../config/solr.yml" unless defined? SOLR_CONFIG

# Load our Solr Configuration (from solr.yml) for our current environment
SOLR_SETTINGS = YAML::load(File.read(SOLR_CONFIG))[RAILS_ENV]

# Set Solr port (default to port 8983 if no port found in solr.yml)
# (This SOLR_PORT variable is used by /lib/tasks/solr.rake when starting Solr)
SOLR_PORT = SOLR_SETTINGS['port'] if SOLR_SETTINGS and SOLR_SETTINGS['port']
SOLR_PORT = "8983" unless defined? SOLR_PORT

# Solr Connection (used by /app/models/index.rb)
SOLRCONN = Solr::Connection.new("http://localhost:#{SOLR_PORT}/solr")