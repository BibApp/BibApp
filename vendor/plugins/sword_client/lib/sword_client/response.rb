# SWORD Client Utilities
#  
# These utilities help to parse information
# out of responses received from a SWORD Server

require 'rexml/document'
# Must require ActiveRecord, as it adds the Hash.from_xml() method (used below)
require 'active_record'

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
  # a Hash similar which has the same general structure
  # as the ATOM XML.  Hash structure is similar to:
  #
  #   {'title' => <Deposited Item Title>,
  #    'id' => <Assigned ID to deposited item>,
  #    'content'  => {'src' => <URL of deposited item>}
  #    'link' => <Array of URLs of uploaded files within item>,
  #    'rights' => <URL of license assigned>,
  #    'server' => {'name' => <SWORD service Name>, 'uri'=> <URI> },
  #    'updated' => <Date deposited item was updated/deposited> }
  #
  def self.post_response_to_hash(response)
    
    #directly convert ATOM reponse to a Ruby Hash (uses REXML by default)
    response_hash = Hash.from_xml(response)

   

    #Remove any keys which represent XML namespace declarations ("xmlns:*")
    # (These are not recognized properly by Hash.from_xml() above)
    response_hash['entry'].delete_if{|key, value| key.to_s.include?("xmlns:")}

    # Return hash under the top 'entry' node
    response_hash['entry']
  end
  
end