# SWORD Client Utilities
#  
# These utilities help to parse information
# out of responses received from a SWORD Server

require 'rexml/document'

class SwordClient::Response
  
  # Retrieve list of available collections from the given 
  # SWORD Service Document.  This list of available collections
  # is based on the access permissions of the authenticated user
  # (or the "on_behalf_of" user, if specified).
  #
  # This will return array of collections, where each
  # collection is represented in a hash similar to
  # (see SourceDocHandler for more details):
  #
  #   {:title => <Collection Title>,
  #    :abstract => <Collection Description>,
  #    :deposit_url => <Collection Deposit URL>,
  #    :accepts => <Accepted MIME Types>,
  #    :namespace => <SWORD namespace URI>,
  #    :collectionPolicy => <Collection License / Policy> }
  #
  def self.get_collections(service_doc_response)
    
    # We will use SAX Parsing with REXML
    src = REXML::Source.new service_doc_response
    
    docHandler = SwordClient::SourceDocHandler.new
    
    #parse Source Doc XML using our custom handler
    REXML::Document.parse_stream src, docHandler
    
    #return discovered collections array   
    docHandler.collections  
  end
  
 
  # Parses the response from post_file() call into 
  # a Hash similar to the following
  # (see PostResponseHandler for more details):
  #
  #   {:title => <Deposited Item Title>,
  #    :deposit_id => <Assigned ID to deposited item>,
  #    :deposit_url  => <URL of deposited item>,
  #    :file_urls => <Array of URLs of uploaded files within item>,
  #    :license_url => <URL of license assigned>,
  #    :server => {:name => <SWORD service Name>, :uri=> <URI> },
  #    :updated => <Date deposited item was updated/deposited>,
  #    :namespace => <SWORD namespace URI> }
  #
  def self.parse_post_response(response)
    
    # We will use SAX Parsing with REXML
    src = REXML::Source.new response
    
    responseHandler = SwordClient::PostResponseHandler.new
    
    #parse Source Doc XML using our custom handler
    REXML::Document.parse_stream src, responseHandler
    
    #return parsed response hash 
    responseHandler.response_hash 
  end
  
end