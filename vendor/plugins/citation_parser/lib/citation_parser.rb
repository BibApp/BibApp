class CitationParser
  
  @@parsers = Array.new
  class << self
    def inherited(subclass)
      @@parsers << subclass
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

    @@parsers.each do |klass|
      parser = klass.new
      @citations = parser.parse(data)
    end
    if @citations.nil?
      return nil
    else
      return @citations
    end
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
