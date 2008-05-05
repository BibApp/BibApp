require 'rexml/streamlistener'
# SourceDocHandler
#
# Uses REXML in stream mode to extract important
# information from a SWORD Source Document.
#
# Gathers an array of all available Collections found
# in that Source Document.  Each Collection is 
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
class SwordClient::SourceDocHandler
  #based of the REXML StreamListener
  include REXML::StreamListener
  
  #Array of collections found
  attr_reader :collections
  
  @curr_collection = nil  #current collection's hash
  @curr_tag_name = nil    #name of current XML tag in <collection>
  
  
  def initialize
    #initialize collection array
    @collections = []
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
    end
  end
  
  
  #Processing when a Text Node is encountered
  def text text
    # if we are inside a <collection> tag
    # save the text as the value of the current XML tag
    if @curr_collection and @curr_tag_name and !@curr_tag_name.empty?
      @curr_collection[@curr_tag_name.to_sym] = text
    end
  end
 
  #Processing when an end tag is encountered
  def tag_end name
    
    #if ending a <collection> tag
    if name=="collection"
      #finished with our current collection, save it and clear
      @collections << @curr_collection
      
      @curr_collection = nil
    end
    
    #clear out current tag name, no matter what
    @curr_tag_name = ""
  end
 
end