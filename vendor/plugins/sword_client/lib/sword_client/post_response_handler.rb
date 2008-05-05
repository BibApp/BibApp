require 'rexml/streamlistener'
# PostResponseHandler
#
# Uses REXML in stream mode to extract important
# information from a SWORD ATOM response after posting a document.
#
# Gathers a hash of information found in the ATOM response
# after posting a document to a SWORD SERVER.  Hash has the
# following general structure:
#
#   {:deposit_id => <Assigned ID to deposited item>,
#    :deposit_url  => <URL of deposited item>,
#    :file_urls => <Array of URLs of uploaded files within item>,
#    :license_url => <URL of license assigned>,
#    :server => {:name => <SWORD service Name>, :uri=> <URI> },
#    :updated => <Date deposited item was updated/deposited> }
#
class SwordClient::PostResponseHandler
  #based of the REXML StreamListener
  include REXML::StreamListener
  
  #Hash which holds our important response info
  attr_reader :response_hash
  
  @in_atom_enty = false   #whether or not we are in the <atom:entry> tag
  @curr_tag_name = nil    #name of current XML tag under <atom:entry>
  
  
  def initialize
    #initialize response hash
    @response_hash = {}
  end
  
  #Processing when a start tag is encountered
  def tag_start name, attrs
    if name=="atom:entry"
      #flip our flag
      @in_atom_entry=true
    
    #if inside a <atom:entry> tag already
    elsif @in_atom_entry
 
      #save current tag name for later
      #only save end of name (e.g. "atom:title" becomes "title")
      @curr_tag_name = name.gsub(/.*:/, '') if name!="atom:name"  #for names we want to keep the parent tag as "curr_tag_name"
      
      
      # Catch tags which have important info in their attributes
      case @curr_tag_name
      when "content" #link to deposited Item itself
        @response_hash[:deposit_url] = attrs["src"]
      when "link" #link to a File which is part of an Item
        if @response_hash[:file_urls]
          @response_hash[:file_urls].push(attrs["href"])
        else
          @response_hash[:file_urls] = [ attrs["href"] ]
        end
      when "generator" #specifics from SWORD server
        @response_hash[:server] = {:uri=>attrs["uri"]}  
      end
    end
  end
  
  
  #Processing when a Text Node is encountered
  def text text
    
    text = text.strip #strip leading/ending whitespace
    
    #do nothing if empty text string
    return if text.nil? or text.empty?
    
    # Gather info, based on our current tag name
    case @curr_tag_name
    when "id" #Item ID / URI
      @response_hash[:deposit_id] = text
    when "rights" #link to Deposit License
      @response_hash[:license_url] = text
    when "generator" #specifics from SWORD server
      @response_hash[:server][:name] = text  
    else #just copy information into hash value which matches tag name
      if @curr_tag_name and !@curr_tag_name.empty?
        #Make an array of values, just in case there's more than one
        if @response_hash[@curr_tag_name.to_sym]
           @response_hash[@curr_tag_name.to_sym].push(text)
        else
           @response_hash[@curr_tag_name.to_sym] = [ text ]
        end
      end
    end
  end
 
  #Processing when an end tag is encountered
  def tag_end name
    
    #clear our curr_tag_name
    @curr_tag_name = ""
  end
 
end