class CitationParser
  
  @@parsers = Array.new
  
  class << self
    def inherited(subclass)
      @@parsers << subclass unless @@parsers.include?(subclass)
    end
    
    def parsers
      @@parsers
    end
  end
  
  attr_reader :citations
  
  def initialize()
    # Populate the internal list of citaitons
    @citations = Array.new
  end
  
  def parse(data)
    @citations = Array.new
    begin
      @@parsers.each do |klass|
        parser = klass.new
        @citations = parser.parse(data)
        
        if !@citations.nil?
          puts("\n Parsing was successful using: #{klass}!\n")
          puts("\nNumber of Successfully Parsed Citations: #{@citations.size}\n")
          return @citations, 1 #Return 1 to indicate everything went fine          
        end       
      end
    

    rescue
    #This error happens when we cannot recover from an error during the parsing.
      return nil, -1 #Return -1 to indicate there was a error
      
    end
    return nil, 0 #Return 0 to indicate that no citations were parsed
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