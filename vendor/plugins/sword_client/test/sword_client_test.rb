#initialize environment
ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'

require 'test/unit'
require 'sword_client'

#load rails environment
require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config/environment.rb'))

class SwordClientTest < Test::Unit::TestCase
  FIX_DIR = "#{File.expand_path(File.dirname(__FILE__))}/fixtures"

  def setup
    
    # @TODO: ENTER IN A VALID SWORD URL, USERNAME AND PASSWORD TO TEST EVERYTHING!
    @sword_url = ""
    @username = ""
    @password = ""
    
    @post_response_doc = nil
  end
 
  def test_bad_url_type
    assert_raise(RuntimeError) do
      SwordClient::Connection.new("ftp://localhost:9999")
    end
  end

  def test_connection_initialize
    connection = SwordClient::Connection.new
    assert_equal 'localhost', connection.url.host
    assert_equal 8080, connection.url.port
    assert_equal '/sword-app', connection.url.path
    
    #test defaults
    assert_nil connection.on_behalf_of
    assert_nil connection.timeout
  end
  
  def test_connection_options
    if !@sword_url or @sword_url.empty?
      sword_path = "http://localhost:8080/sword-app/" 
    else
      sword_path = @sword_url
    end
    connection = SwordClient::Connection.new(sword_path, {:on_behalf_of => "someone_else"})
    
    assert_equal "someone_else", connection.on_behalf_of
  end
  
  def test_proxy_settings
    if !@sword_url or @sword_url.empty?
      sword_path = "http://localhost:8080/sword-app/" 
    else
      sword_path = @sword_url
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
    # tests initialization from RAILS_ROOT/config/sword.yml
    client = SwordClient.new
    
    assert_instance_of SwordClient::Connection, client.connection
    assert !client.connection.nil?
    
    assert client.config['base_url']  #base url should always be in config!
    
    assert client.connection.url()
 
  end
   
  # By default SWORD usually requires authorization...
  # However, this test will FAIL if you turn off authorization  
  def test_require_auth
    if @sword_url.empty? or @username.empty? or @password.empty?
      flunk "Because SwordClient actually connects to an existing SWORD Server, many of its tests require a valid SWORD URL, username and password. You can specify these in the 'setup()' of sword_client_test.rb so those tests don't fail by default."
    end
    
    connection = SwordClient::Connection.new(@sword_url)
    
    assert_raise(Net::HTTPServerException) do
      connection.service_document    
    end
  end
  
  def test_invalid_service_doc
    if @sword_url.empty? or @username.empty? or @password.empty?
      flunk "Because SwordClient actually connects to an existing SWORD Server, many of its tests require a valid SWORD URL, username and password. You can specify these in the 'setup()' of sword_client_test.rb so those tests don't fail by default."
    end
    
    connection = SwordClient::Connection.new(@sword_url)
    
    assert_raise(Net::HTTPServerException) do
      connection.service_document("blahblahblah")    
    end
  end
  
  def test_invalid_login
    if @sword_url.empty? or @username.empty? or @password.empty?
      flunk "Because SwordClient actually connects to an existing SWORD Server, many of its tests require a valid SWORD URL, username and password. You can specify these in the 'setup()' of sword_client_test.rb so those tests don't fail by default."
    end
    
    connection = SwordClient::Connection.new(@sword_url, {:username=>"not_a_user_name", :password=>"blahblahblah"})
    assert_raise(Net::HTTPServerException) do
      connection.service_document  
    end
  end
  
  # This test will ALWAYS fail until you add in a valid SWORD URL, username & password
  def test_valid_service_doc
    
    if @sword_url.empty? or @username.empty? or @password.empty?
      flunk "Because SwordClient actually connects to an existing SWORD Server, many of its tests require a valid SWORD URL, username and password. You can specify these in the 'setup()' of sword_client_test.rb so those tests don't fail by default."
    end
  
    connection = SwordClient::Connection.new(@sword_url, {:username=>@username, :password=>@password})
    
    doc = connection.service_document
    
    #Uncomment to see the Service Document
    #puts doc  
      
    #make sure our service doc structure looks OK
    assert_match(/<\?xml[^<>]*>[\s]*<service[^<>]*>[\s]*<sword:level[^<>]*>.*<\/sword:level>.*<workspace>[\s]*<atom:title[^<>]*>.*<\/atom:title>.*<\/workspace>.*<\/service>/m, doc)
  end
  
  # This test will ALWAYS fail until you add in a valid SWORD URL, username & password
  def test_get_collections
   
    if @sword_url.empty? or @username.empty? or @password.empty?
      flunk "Because SwordClient actually connects to an existing SWORD Server, many of its tests require a valid SWORD URL, username and password. You can specify these in the 'setup()' of sword_client_test.rb so those tests don't fail by default."
    end
  
    connection = SwordClient::Connection.new(@sword_url, {:username=>@username, :password=>@password})
    
    #retrieve our available collections and check them out
    doc = connection.service_document
    collections = SwordClient::Response.get_collections(doc)
    assert_instance_of Array, collections
    
    #check in more detail
    collections.each do |c|
      #at very least each collection should have a title & URL
      assert c[:title]
      assert c[:deposit_url]
    end
  end
  
  # This test will ALWAYS fail until you add in a valid SWORD URL, username & password
  def test_post_file
    
    if @sword_url.empty? or @username.empty? or @password.empty?
      flunk "Because SwordClient actually connects to an existing SWORD Server, many of its tests require a valid SWORD URL, username and password. You can specify these in the 'setup()' of sword_client_test.rb so those tests don't fail by default."
    end
  
    connection = SwordClient::Connection.new(@sword_url, {:username=>@username, :password=>@password})
    
    #get available collections
    doc = connection.service_document
    collections = SwordClient::Response.get_collections(doc)
    assert_instance_of Array, collections
    assert !collections.empty?
    
    puts "\n\nTesting Deposit"
    puts "\nFile: #{FIX_DIR}/sword-example.zip"
    puts "\nDepositing to: " + collections[0][:deposit_url] + "\n"
    
    #as a test, we'll just post to first collection found
    post_response_doc = connection.post_file("#{FIX_DIR}/sword-example.zip", collections[0][:deposit_url])
    
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
