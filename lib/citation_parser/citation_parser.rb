#
# CitationParser plugin
#
# This class calls our defined Citation Parsers to actually
# generate Ruby Hashes from various citation file formats.
# http://bibapp.googlecode.com/
#
class CitationParser
  #Must require ActiveRecord so we have access to Rails Unicode tools
  # See: http://api.rubyonrails.org/classes/ActiveSupport/CoreExtensions/String/Unicode.html
  require 'active_record' 
  
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
  
  #Primary parse method.
  # Tries each defined CitationParser, and calls their parse_data()
  # method in an attempt to parse unknown data.
  def parse(data)
    @citations = Array.new
    
    @@parsers.each do |klass|
      parser = klass.new

      @citations = parser.parse_data(data) if parser.respond_to?(:parse_data)

      unless @citations.blank?
        @citations = cleanup_cites(@citations)
        
        CitationParser.logger.debug("\nSuccessfully parsed #{@citations.size} citations using: #{klass}!\n")
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

#Load BaseXmlParser first, then all format-specific citation importers.
require "#{File.expand_path(File.dirname(__FILE__))}/base_xml_parser.rb"
Dir["#{File.expand_path(File.dirname(__FILE__))}/citation_parsers/*_parser.rb"].each { |p| require p }