# SWORD Client Utilities
#  
# These utilities help to parse information
# out of responses received from a SWORD Server

require 'rexml/document'

class SwordClient::Response
  
  # Parse the given SWORD Service Document.  
  #
  # Returns a SwordClient::ParsedServiceDoc which contains 
  # all information which was able to be parsed from
  # the SWORD Service Document
  def self.parse_service_doc(service_doc_response)
    
    # We will use SAX Parsing with REXML
    src = REXML::Source.new service_doc_response
    
    docHandler = SwordClient::ServiceDocHandler.new
    
    #parse Source Doc XML using our custom handler
    REXML::Document.parse_stream src, docHandler
    
    #return SwordClient::ParsedServiceDoc 
    docHandler.parsed_service_doc
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