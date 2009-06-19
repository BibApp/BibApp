require 'rexml/streamlistener'
# ServiceDocHandler
#
# Uses REXML in stream mode to extract important
# information from a SWORD Service Document.  This method parses
# the SWORD Service Document into a SwordClient::ParsedServiceDoc
#
# Gathers an array of all available Collections found
# in that Service Document.  Each Collection is 
# represented by a Hash of the following general structure
# (which mirrors SWORD service document structure under <collection> tag):
#
# :collections =>
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
#
# Also parses out general information about the SWORD server:
#
# :repository_name => <Name of the Repository>
# :version => <Version of SWORD supported>
# :max_upload_size => <Maximum size of upload>
# :verbose => <Verbose mode allowed?>
# :no_op => <No operation mode supported?>
#
class SwordClient::ServiceDocHandler
  #based of the REXML StreamListener
  include REXML::StreamListener
  
  #Reference to ParsedServiceDoc
  attr_reader :parsed_service_doc
  
  @curr_collection = nil  #current collection's hash
  @curr_tag_name = nil    #name of current XML tag in the stream
 
  # Name of a collection tag (used to parse out specific info for each collection)
  COLLECTION_TAG = "app:collection"
  # Name of SWORD's "acceptPackaging" tag (used to parse out the 'ranking' for each package format)
  ACCEPT_PACKAGING_TAG = "sword:acceptPackaging"

  @accept_packaging_rank = 0;


  def initialize
    #initialize our ParsedServiceDoc
    @parsed_service_doc = SwordClient::ParsedServiceDoc.new
  end


  #Processing when a start tag is encountered (e.g. <sword>)
  def tag_start name, attrs

    #save current tag name for later (for usage in text() method below)
    @curr_tag_name = name

    #if starting a <app:collection> tag
    if @curr_tag_name==COLLECTION_TAG
      #Initialize current collection's info, starting with its Deposit URL
      @curr_collection = {'deposit_url' => attrs["href"]}

    #Special case: the <acceptPackaging> tag includes a numerical ranking between
    # 0 and 1 for each accepted format -- this ranking indicates the preferred format(s)
    elsif @curr_tag_name==ACCEPT_PACKAGING_TAG
        #If a "q" attribute is not found, assume this format is strongest preference (1.0)
        @accept_packaging_rank = attrs["q"] ? attrs["q"].to_f : 1.0
    end
  end
  
  
  #Processing when a Text Node is encountered
  def text text

    #convert value to string and strip off leading/trailing spaces
    value = text.to_s.strip

    #do nothing if empty value
    return if value.nil? or value.empty?
    
    # if we are inside a <collection> tag
    # save the text as the value of the current XML tag
    if @curr_collection and @curr_tag_name and !@curr_tag_name.empty? and @curr_tag_name!=COLLECTION_TAG

        # Save text as a property of the current collection
        # (e.g. collection['title'] = "Collection Title",
        #       collection['collectionPolicy'] = "Collection License", etc.)
        prop_name = tag_to_property_name @curr_tag_name

        # Special case:  For the <acceptPackaging> tag, the value is a hash
        #  of the ranking ("q") and the packaging format.
        if @curr_tag_name==ACCEPT_PACKAGING_TAG
           save_collection_prop_value prop_name, {'rank'=>@accept_packaging_rank, 'value'=>value} if @accept_packaging_rank > 0
           @accept_packaging_rank = 0.0  #reset rank back to zero
        else
           save_collection_prop_value prop_name, value
        end
    
    #If we aren't in a collection, and we encounter an <atom:title>, 
    # then we've found the repository's name
    elsif !@curr_collection and @curr_tag_name and @curr_tag_name=="atom:title"
        #capture the repository's name
        @parsed_service_doc.repository_name = value

    #Save any global properties encountered
    elsif !@curr_collection and @curr_tag_name and @curr_tag_name.include?("sword:")
        case @curr_tag_name
        when "sword:version"
            @parsed_service_doc.version = value
        when "sword:verbose"
            @parsed_service_doc.verbose = value
        when "sword:noOp"
            @parsed_service_doc.no_op = value
        when "sword:maxUploadSize"
            @parsed_service_doc.max_upload_size = value
        end
    end
  end
 
  #Processing when an end tag is encountered  (e.g. </sword>)
  def tag_end name
    
    #if ending a </app:collection> tag
    if name=="app:collection"
      #finished with our current collection, save it and clear out current collection
      @parsed_service_doc.collections << @curr_collection
      @curr_collection = nil
    end
    
    #clear out current tag name, no matter what
    @curr_tag_name = ""
  end


  ##################
  # Private Methods
  ##################
  private

  #Convert an XML tag to a valid property name for a Collection
  # (e.g. "atom:title" becomes 'title')
  def tag_to_property_name tag_name
      tag_name.gsub(/.*:/, '')
  end

  # Saves a property value for the current collection.
  # This method ensures that multiple values are changed into an
  # array of values
  def save_collection_prop_value prop_name, value
      #If this property already had a previous value(s) for this collection,
      # then we want to change this property into an array of all its values
      if @curr_collection[prop_name]
        #If not already an Array, change into an Array
        if !@curr_collection[prop_name].kind_of?(Array)
          #Change property into an array of values
          first_value = @curr_collection[prop_name]
          @curr_collection[prop_name] = [ first_value ]
        end
       
        #append onto current array of values
        @curr_collection[prop_name] << value
      else
        @curr_collection[prop_name] = value
      end
  end
end