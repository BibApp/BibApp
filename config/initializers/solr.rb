# Solr Path (in /vendor/solr)
SOLR_PATH = "#{File.dirname(__FILE__)}/../../vendor/solr" unless defined? SOLR_PATH

# Solr Port
SOLR_PORT = "8983" unless defined? SOLR_PORT

# Solr Connection
SOLRCONN = Solr::Connection.new("http://localhost:#{SOLR_PORT}/solr")