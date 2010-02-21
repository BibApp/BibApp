class Identifier < ActiveRecord::Base
  
  belongs_to :publication
  has_many :identifyings, :dependent => :delete_all

  @@parsers = [ISSN, ISBN]
  
  class << self
    def inherited(subclass)
      @@parsers << subclass unless @@parsers.include?(subclass)
    end
  end

  #Primary parse method.
  # Tries each defined Identifier subklass, and calls their parse_identifier()
  # method in an attempt to parse unknown identifier.
  def parse(identifier)

   @identifiers = Array.new

   @@parsers.each do |klass|
     parser = klass.new
     @format, @identifier, @response = parser.parse_identifier(identifier) if parser.respond_to?(:parse_identifier)
     unless @response.blank?
       return @format, @identifier, @response
     end       
   end
 
   return @format, @identifier, @response
  end
end