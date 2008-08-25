#initialize environment
RAILS_ENV = 'test'

require 'test/unit'
require 'sword_client'
require 'yaml'

class SwordClientTest < Test::Unit::TestCase
  FIX_DIR = "#{File.expand_path(File.dirname(__FILE__))}/fixtures"

  #Required Setup for all tests
  def setup
    
    # @TODO: ENTER IN A VALID SWORD URL, USERNAME AND PASSWORD TO TEST EVERYTHING!
    @service_doc_url = "http://localhost:8080/sword-app/servicedocument"
    @username = ""
    @password = ""
    
  end
 
  def test_bad_url_type
    assert_raise(SwordClient::SwordException) do
      SwordClient::Connection.new("ftp://localhost:9999")
    end
  end

  def test_connection_initialize
    
    #Make sure all defaults get initialized properly
    connection = SwordClient::Connection.new
    assert_equal 'localhost', connection.url.host
    assert_equal 8080, connection.url.port
    assert_equal '/sword-app/servicedocument', connection.url.path
    
    #test defaults
    assert_nil connection.on_behalf_of
    assert_nil connection.timeout
  end
  
  def test_connection_options
    if !@service_doc_url or @service_doc_url.empty?
      sword_path = "http://localhost:8080/sword-app/servicedocument" 
    else
      sword_path = @service_doc_url
    end
    connection = SwordClient::Connection.new(sword_path, {:on_behalf_of => "someone_else"})
    
    assert_equal "someone_else", connection.on_behalf_of
  end
  
  def test_proxy_settings
    if !@service_doc_url or @service_doc_url.empty?
      sword_path = "http://localhost:8080/sword-app/servicedocument" 
    else
      sword_path = @service_doc_url
    end
    connection = SwordClient::Connection.new(sword_path, {:proxy_settings => {:server => "my.proxy.edu", :port => 80, :username => "username", :password=>"mypass"}})
    
    assert_equal "my.proxy.edu", connection.proxy_settings[:server]
    assert_equal 80, connection.proxy_settings[:port]
    assert_equal "username", connection.proxy_settings[:username]
    assert_equal "mypass", connection.proxy_settings[:password]
  end

  def test_non_standard_url
    connection = SwordClient::Connection.new("http://localhost:8080/my-sword-path")
    assert_equal '/my-sword-path', connection.url.path
  end
  
  def test_load_from_config
    # tests initialization from test/fixtures/sword.yml
    client = SwordClient.new("#{FIX_DIR}/sword.yml")
    
    assert_not_nil client.connection
    assert_instance_of SwordClient::Connection, client.connection
    
    assert client.config['service_doc_url']  #service_doc_url should always be in config!
    
    assert_equal client.config['service_doc_url'], "http://localhost:8080/sword-app/servicedocument"
    assert_equal client.config['username'], "myusername"
    
    assert client.connection.url()
 
  end
   
  # By default SWORD usually requires authorization...
  # However, this test will FAIL if you turn off authorization  
  def test_require_auth
    if @service_doc_url.empty? or @username.empty? or @password.empty?
      flunk "Because SwordClient actually connects to an existing SWORD Server, many of its tests require a valid SWORD URL, username and password. You can specify these in the 'setup()' of sword_client_test.rb so those tests don't fail by default."
    end
    
    connection = SwordClient::Connection.new(@service_doc_url)
    
    assert_raise(Net::HTTPServerException) do
      connection.service_document    
    end
  end
  
  def test_invalid_service_doc
    if @service_doc_url.empty? or @username.empty? or @password.empty?
      flunk "Because SwordClient actually connects to an existing SWORD Server, many of its tests require a valid SWORD URL, username and password. You can specify these in the 'setup()' of sword_client_test.rb so those tests don't fail by default."
    end
    
    connection = SwordClient::Connection.new(@service_doc_url + "/blahblahblah")
    
    assert_raise(Net::HTTPServerException) do
      connection.service_document 
    end
  end
  
  def test_invalid_login
    if @service_doc_url.empty? or @username.empty? or @password.empty?
      flunk "Because SwordClient actually connects to an existing SWORD Server, many of its tests require a valid SWORD URL, username and password. You can specify these in the 'setup()' of sword_client_test.rb so those tests don't fail by default."
    end
    
    connection = SwordClient::Connection.new(@service_doc_url, {:username=>"not_a_user_name", :password=>"blahblahblah"})
    assert_raise(Net::HTTPServerException) do
      connection.service_document  
    end
  end
  
  # This test will ALWAYS fail until you add in a valid SWORD URL, username & password
  def test_valid_service_doc
    
    if @service_doc_url.empty? or @username.empty? or @password.empty?
      flunk "Because SwordClient actually connects to an existing SWORD Server, many of its tests require a valid SWORD URL, username and password. You can specify these in the 'setup()' of sword_client_test.rb so those tests don't fail by default."
    end
  
    connection = SwordClient::Connection.new(@service_doc_url, {:username=>@username, :password=>@password})
    
    doc = connection.service_document
    
    #Uncomment to see the Service Document
    #puts doc  
      
    #make sure our service doc structure looks OK
    assert_match(/<\?xml[^<>]*>[\s]*<service[^<>]*>[\s]*<sword:level[^<>]*>.*<\/sword:level>.*<workspace>[\s]*<atom:title[^<>]*>.*<\/atom:title>.*<\/workspace>.*<\/service>/m, doc)
  end
  
  # This test will ALWAYS fail until you add in a valid SWORD URL, username & password
  def test_get_collections
   
    if @service_doc_url.empty? or @username.empty? or @password.empty?
      flunk "Because SwordClient actually connects to an existing SWORD Server, many of its tests require a valid SWORD URL, username and password. You can specify these in the 'setup()' of sword_client_test.rb so those tests don't fail by default."
    end
  
    connection = SwordClient::Connection.new(@service_doc_url, {:username=>@username, :password=>@password})
    
    #retrieve service doc and parse it
    doc = connection.service_document
    parsed_doc = SwordClient::Response.parse_service_doc(doc)
    assert_instance_of SwordClient::ParsedServiceDoc, parsed_doc
      
    #retrieve collections and check
    assert_instance_of Array, parsed_doc.collections
    
    #check in more detail
    parsed_doc.collections.each do |c|
      #at very least each collection should have a title & URL
      assert c[:title]
      assert c[:deposit_url]
    end
  end
  
  # This test will ALWAYS fail until you add in a valid SWORD URL, username & password
  def test_post_file
    
    if @service_doc_url.empty? or @username.empty? or @password.empty?
      flunk "Because SwordClient actually connects to an existing SWORD Server, many of its tests require a valid SWORD URL, username and password. You can specify these in the 'setup()' of sword_client_test.rb so those tests don't fail by default."
    end
  
    connection = SwordClient::Connection.new(@service_doc_url, {:username=>@username, :password=>@password})
    
    #get available collections
    doc = connection.service_document
    parsed_doc = SwordClient::Response.parse_service_doc(doc)
    assert_instance_of Array, parsed_doc.collections
    assert !parsed_doc.collections.empty?
    
    puts "\n\nTesting Deposit"
    puts "\nFile: #{FIX_DIR}/sword-example.zip"
    puts "\nDepositing to: " + parsed_doc.collections[0][:deposit_url] + "\n"
    
    #as a test, we'll just post to first collection found
    post_response_doc = connection.post_file("#{FIX_DIR}/sword-example.zip", parsed_doc.collections[0][:deposit_url])
    
    #Uncomment to see the ATOM response
    #puts post_response_doc
      
    #make sure our ATOM response structure looks OK
    assert_match(/<\?xml[^<>]*>[\s]*<atom:entry[^<>]*>[\s]*<atom:id[^<>]*>.*<\/atom:id>.*<atom:title[^<>]*>.*<\/atom:title>.*<atom:updated[^<>]*>.*<\/atom:updated>.*<\/atom:entry>/m, post_response_doc)
  
    #Parse response into Hash
    response_hash = SwordClient::Response.parse_post_response(post_response_doc)
    assert_instance_of Hash, response_hash
    
    #Uncomment to see the parsed out hash
    #puts response_hash.inspect
    
    #check Hash in more detail
    assert response_hash[:deposit_id]
    assert response_hash[:deposit_url]
    assert response_hash[:updated]
    assert response_hash[:title]
  
  end


  
end
