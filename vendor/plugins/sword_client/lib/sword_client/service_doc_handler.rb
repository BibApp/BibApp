require 'rexml/streamlistener'
# ServiceDocHandler
#
# Uses REXML in stream mode to extract important
# information from a SWORD Service Document.
#
# Gathers an array of all available Collections found
# in that Service Document.  Each Collection is 
# represented by a Hash of the following general structure
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
#
class SwordClient::ServiceDocHandler
  #based of the REXML StreamListener
  include REXML::StreamListener
  
  #Reference to ParsedServiceDoc
  attr_reader :parsed_service_doc
  
  @curr_collection = nil  #current collection's hash
  @curr_tag_name = nil    #name of current XML tag in <collection>
  
  @in_repository_title = false   # whether in <workspace><atom:title> tag
  
  
  def initialize
    #initialize our ParsedServiceDoc
    @parsed_service_doc = SwordClient::ParsedServiceDoc.new
  end
  
  #Processing when a start tag is encountered
  def tag_start name, attrs
    if name=="collection"
      #Initialize current collection info, with its Deposit URL
      @curr_collection = {:deposit_url=>attrs["href"]}
    
    #if inside a <collection> tag already
    elsif @curr_collection
      #save current tag name for later
      #only save end of name (e.g. "atom:title" becomes "title")
      @curr_tag_name = name.gsub(/.*:/, '')
    elsif !@curr_collection and name=="atom:title"  
      #capture the repository's name, which is under <workspace><atom:title>...</workspace>
      @in_repository_title = true
    end
  end
  
  
  #Processing when a Text Node is encountered
  def text text
    # if we are inside a <collection> tag
    # save the text as the value of the current XML tag
    if @curr_collection and @curr_tag_name and !@curr_tag_name.empty?
      @curr_collection[@curr_tag_name.to_sym] = text
    elsif @in_repository_title
      #capture the repository's name
      @parsed_service_doc.repository_name = text
    end
  end
 
  #Processing when an end tag is encountered
  def tag_end name
    
    #if ending a <collection> tag
    if name=="collection"
      #finished with our current collection, save it and clear
      @parsed_service_doc.collections << @curr_collection
      
      @curr_collection = nil
    end
    
    #clear out current tag name, no matter what
    @curr_tag_name = ""
    #clear out flag which tells us to grab repository's title/name
    @in_repository_title = false
  end
 
end