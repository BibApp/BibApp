# ParsedServiceDoc
#
# Contains the parsed contents of a SWORD
# Service Document.
#
class SwordClient::ParsedServiceDoc

  #Array of collections found in Service Doc
  # Each Collection is represented by a Hash 
  # of the following general structure
  # (which mirrors structure under <collection> tag):
  #
  #   {:title => <Collection Title>,
  #    :abstract => <Collection Description>,
  #    :deposit_url => <Collection Deposit URL>,
  #    :accepts => <Accepted MIME Types>,
  #    :namespace => <SWORD namespace URI>,
  #    :collectionPolicy => <Collection License / Policy>,
  #    :mediation => <SWORD Mediation flag>,
  #    :treatment => <SWORD treatment statement> }
  attr_accessor :collections
  
  #Name of repository found in Service Doc
  attr_accessor :repository_name
  
  def initialize
    #initialize collection array
    @collections = []
  end
  
end