class CitationParser
  
  @@parsers = Array.new
  
  class << self
    def inherited(subclass)
      @@parsers << subclass unless @@parsers.include?(subclass)
    end
    
    def parsers
      @@parsers
    end
    
    def logger
      #Use RAILS_DEFAULT_LOGGER by default for all logging
      @@logger ||= ::RAILS_DEFAULT_LOGGER
    end
  end
  
  attr_reader :citations
  
  def initialize()
    # Populate the internal list of citaitons
    @citations = Array.new
  end
  
  def parse(data)
    @citations = Array.new
    
    @@parsers.each do |klass|
      parser = klass.new
      @citations = parser.parse(data)

      unless @citations.nil?
        @citations = cleanup_cites(@citations)
        
        CitationParser.logger.debug("\n Successfully parsed #{@citations.size} citations using: #{klass}!\n")
        return @citations          
      end       
    end
   
    return nil
  end
  
  ## Cleanup the citation attribute hash
  def cleanup_cites(cites)
    
    cites.each do |cite|
      hash = cite.properties
      
      #cleanup our citation properties
      hash.each do |key, value|

        #First, flatten any arrays within arrays, etc.
        if !value.nil? and value.respond_to? :flatten
          value = value.flatten
        end
        
        #remove key's which have nil or empty values
        #This removes empty Arrays, Hashes and Strings
        if value.nil? or value.empty?
          hash.delete(key)
          next
        end

        #save cleaned value
        hash[key] = value
      end
    end  
    return cites
  end
  
  
  protected
  attr_writer :citations
end

class ParsedCitation
  attr_reader :citation_type
  attr_accessor :properties

  def initialize(type)
    @citation_type = type
    @properties = Hash.new
  end
end

Dir["#{File.expand_path(File.dirname(__FILE__))}/citation_parsers/*_parser.rb"].each { |p| require p }