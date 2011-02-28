class Identifier < ActiveRecord::Base

  belongs_to :publication
  has_many :identifyings, :dependent => :destroy

  @@parsers = [ISSN, ISBN]

  def self.inherited(subclass)
    @@parsers << subclass unless @@parsers.include?(subclass)
  end

  #override for subclasses if this isn't appropriate
  def self.format_string
    self.to_s
  end

  #Primary parse method.
  #tries with each Identifier subclass to parse
  #Returns an array of arrays (possible empty). For each successful parse return an array [Subclass, cleaned_identifier]
  def self.parse(identifier)

    identifiers = Array.new

    @@parsers.each do |klass|
      id = klass.parse_identifier(identifier)
      if id
        identifiers << [klass, id]
      end
    end

    return identifiers
  end

  #override to return true if the identifier is valid for a subclass
  def self.is_valid?(identifier)
    return false
  end

  #override if a subclass needs to do specialized parsing
  def self.parse_identifier(identifier)
    if is_valid?(identifier)
      return cleanup(identifier)
    else
      return nil
    end
  end

  #override if a subclass needs to do specialized cleaning for an identifier
  def self.cleanup(identifier)
    return identifier
  end

end