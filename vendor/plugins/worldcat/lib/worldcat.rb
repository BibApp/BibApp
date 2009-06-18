class WorldCat
  
  attr_accessor :config
  
  def initialize(config_path="config/worldcat.yml")
    @config = WorldCat.load_api_config(config_path)
  end
  
  #Load our WorldCat Configurations from worldcat.yml
  def self.load_api_config(config_path)
    YAML::load(File.read(config_path))
  end
end

# Require subklasses
Dir["#{File.expand_path(File.dirname(__FILE__))}/worldcat/request/*.rb"].each{|file| require file}
Dir["#{File.expand_path(File.dirname(__FILE__))}/worldcat/response/*.rb"].each{|file| require file}