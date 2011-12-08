#define a custom exception for Sword Client
class SwordException < Exception; end

# A Ruby-based SWORD Client
#
# This allows you to make requests (via HTTP) to an existing
# SWORD Server, including posting a file to a SWORD server.
#
# For more information on SWORD and the SWORD APP Profile:
#  http://www.swordapp.org/
#
# == Configuration
#
# Configuration is done via <tt>RAILS_ROOT/config/sword.yml</tt>
# and is loaded according to the <tt>RAILS_ENV</tt>.
# The minimum connection options that you must specify depend
# on the location of your SWORD server (and whether it requires
# authentication).  Minimally, you likely need to change
# "SWORD Service Document URL" and "SWORD Server Default Login"
#
# Example production configuration (RAILS_ROOT/config/sword.yml)
#
# production:
#   # SWORD Server's Service Document URL
#   service_doc_url: http://localhost:8080/sword-app/servicedocument
#
#   # SWORD Server Default Login credentials
#   username:
#   password:
#
#   # Proxy Settings
#   #   Only necessary if you require a Proxy
#   #   to connect to SWORD Server.  If using
#   #   a proxy, only the proxy_server is required.
#   proxy_server: my.proxy.edu
#   proxy_port: 80
#   proxy_username: myproxyuser
#   proxy_password: myproxypass
#
#   # Default Collection to deposit to
#   #   URL should correspond to the Deposit URL
#   #   of a collection as returned by Service Document.
#   #   If unspecified, then a user will need to
#   #   select a collection *before* a deposit
#   #   can be made via SWORD
#   #
#   #   Either specify the Name of the Collection
#   #   OR specify the URL (but not BOTH!)
#   default_collection_url: http://localhost:8080/sword-app/deposit/123456789/4
#   #default_collection_name: My Collection
#
#
#
# You can change the location of the config path by passing a full path
# to the init_connection method.
#
#   SWORDClient.init_connection(RAILS_ROOT + '/config/sword.yml')
#

class SwordClient

  # Currently initialized SWORD Connection
  attr_accessor :connection

  # Currently loaded SWORD configurations
  # from RAILS_ROOT/config/sword.yml
  attr_accessor :config

  # Currently loaded SWORD service document
  attr_writer :service_doc

  # Currently parsed SWORD service document
  attr_writer :parsed_service_doc

  class << self
    def logger
      #Use RAILS_DEFAULT_LOGGER by default for all logging
      @@logger ||= ::RAILS_DEFAULT_LOGGER
    end
  end

  #Initialize a SWORD Connection,
  # based on the configurations
  # read from sword.yml.
  #
  # This only *initializes* a SWORDClient::Connection,
  # and doesn't connect to SWORD Server yet
  def initialize(config_path="#{Rails.root}/config/sword.yml")

    # Make sure sword.yml config exists
    raise SwordException, "Could not find SwordClient configuration file at " + config_path if(!File.exists?(config_path))

    #Load our configurations
    @config = SwordClient.load_sword_config(config_path)

    # Check for Service Document URL (service_doc_url), which is required
    raise SwordException, "The SwordClient configuration file (sword.yml) exists, but the 'service_doc_url' is not set for your current environment." if !@config['service_doc_url'] or @config['service_doc_url'].empty?

    #build our connection params from configurations
    params = {}
    params[:debug_mode] = true if @config['debug_mode']
    params[:username] = @config['username'] if @config['username'] and !@config['username'].empty?
    params[:password] = @config['password'] if @config['password'] and !@config['password'].empty?

    #if using a proxy, we need to init proxy settings
    if @config['proxy_server'] and !@config['proxy_server'].empty?
      proxy_settings = {}
      proxy_settings[:server] = @config['proxy_server']
      proxy_settings[:port] = @config['proxy_port'] if @config['proxy_port'] and !@config['proxy_port'].empty?
      proxy_settings[:username] = @config['proxy_username'] if @config['proxy_username'] and !@config['proxy_username'].empty?
      proxy_settings[:password] =  @config['proxy_password'] if @config['proxy_password']and !@config['proxy_password'].empty?

      #add all our proxy settings to params
      params[:proxy_settings] = proxy_settings
    end

    #initialize our SWORD connection
    # (Note: this doesn't actually connect to SWORD, yet!)
    @connection = SwordClient::Connection.new(@config['service_doc_url'], params)
  end

  #Tests if the SwordClient seems to be configured
  # by attempting to initialize it based on sword.yml
  def self.configured?
    begin
      client = SwordClient.new
      return true if client.kind_of?(SwordClient)
    rescue SwordException, Exception
      #rescue any exception, but do nothing
    end
    return false
  end

  # Retrieve the SWORD Service Document for current connection,
  # based on configs read from sword.yml.
  def service_document

    if !@service_doc #use already cached service doc, if exists
      if @config['service_doc_path'] and !@config['service_doc_path'].empty?
        @service_doc = @connection.service_document(@config['service_doc_path'])
      else
        @service_doc = @connection.service_document
      end
    end

    @service_doc
  end

  # Retrieve and parse the SWORD Service Document for current connection,
  # based on configs read from sword.yml.
  #
  # This returns a SwordClient::ParsedServiceDoc.  In addition, it caches
  # this parsed service document for future requests using same client.
  def parsed_service_document

    if !@parsed_service_doc  #use already cached service doc, if exists
      #get service doc
      doc = service_document

      #parse it into a SwordClient::ParsedServiceDoc
      @parsed_service_doc = SwordClient::Response.parse_service_doc(doc)
    end

    @parsed_service_doc
  end


  # Posts a file to the SWORD connection for deposit.
  #   Paths are initialized based on configs read from sword.yml
  #
  # If deposit URL is unspecified, it posts to the
  # default collection (if one is specified in sword.yml)
  #
  # For a list of valid 'headers', see Connection.post_file()
  def post_file(file_path, deposit_url=nil, headers={})

    if deposit_url.nil?
      #post to default collection, if there is one
      default_col = get_default_collection
      deposit_url = default_col['deposit_url'] if default_col
    end

    #only post file if we have some sort of deposit url!
    if deposit_url and !deposit_url.empty?
      @connection.post_file(file_path, deposit_url, headers)
    else
      raise SwordException.new, "File '#{file_path}' could not be posted via SWORD as no deposit URL (or default collection) was specified!"
    end
  end

  # Retrieve array of available collections from the currently loaded
  # SWORD Service Document.  Each collection is represented by a
  # hash of attributes.
  #
  # Caches this array of collections for future requests using same client.
  #
  # See SwordClient::ParsedServiceDoc for hash structure.
  def get_collections

    #get parsed service document
    parsed_doc = parsed_service_document

    #return parsed out collections
    parsed_doc.collections
  end


  # Retrieve collection hash for the Collection that has
  # been specified (in sword.yml) as the "default" collection
  # for all SWORD deposits.  This pulls the information from
  # the currently loaded Service Document.
  #
  # See SwordClient::ParsedServiceDoc for hash structure.
  def get_default_collection

    # get our available collections
    colls = get_collections

    #locate our default collection, based on configs loaded from sword.yml
    default_collection = nil
    colls.each do |c|
      if @config['default_collection_url']
        default_collection = c if c['deposit_url'].to_s.strip == @config['default_collection_url'].strip
        break if default_collection #first matching collection wins!
      elsif @config['default_collection_name']
        default_collection = c if c['title'].to_s.strip.downcase == @config['default_collection_name'].strip.downcase
        break if default_collection #first matching collection wins!
      end
    end

    default_collection
  end

  # Retrieve repository name from the currently loaded
  # SWORD Service Document.
  def get_repository_name

    #get parsed service document
    parsed_doc = parsed_service_document

    #return parsed out repository name
    parsed_doc.repository_name
  end

  private

  #Load our SWORD Configurations from sword.yml
  def self.load_sword_config(config_path)
    YAML::load(File.read(config_path))[::Rails.env]
  end

end

#load SwordClient sub-classes
require 'sword_client/connection'
require 'sword_client/service_doc_handler'
require 'sword_client/response'
require 'sword_client/parsed_service_doc'
