# ParsedServiceDoc
#
# Contains the parsed contents of a SWORD
# Service Document.
#
class SwordClient::ParsedServiceDoc

  # SWORD version & other top level properties specified in Service Doc
  attr_accessor :version
  attr_accessor :verbose
  attr_accessor :no_op
  attr_accessor :max_upload_size
  
  #Array of collections found in Service Doc
  # Each Collection is represented by a Hash 
  # of the following general structure
  # (which mirrors SWORD structure under <collection> tag):
  #
  #   {'title' => <Collection Title>,
  #    'abstract' => <Collection Description>,
  #    'deposit_url' => <Collection Deposit URL>,
  #    'accept' => <Accepted MIME Types>,
  #    'acceptPackaging' =>
  #         {'rank' => <format rank between 0-1>,
  #          'value' => <Accepted package format> },
  #    'collectionPolicy' => <Collection License / Policy>,
  #    'mediation' => <Whether or not Mediation is supported>,
  #    'treatment' => <SWORD treatment statement> }
  attr_accessor :collections
  
  #Name of repository found in Service Doc
  attr_accessor :repository_name

  def initialize
    #initialize collection array
    @collections = []
  end
  
end