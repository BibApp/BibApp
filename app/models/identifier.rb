class Identifier < ActiveRecord::Base

  has_many :publications, :through => :identifyings
  has_many :identifyings, :dependent => :destroy

  #override for subclasses if this isn't appropriate
  def self.id_type_string
    self.to_s
  end

  #Primary parse method.
  #tries with each Identifier subclass to parse
  #Returns an array of arrays (possible empty). For each successful parse return an array [Subclass, cleaned_identifier]
  def self.parse(identifier)

    identifiers = Array.new

    self.descendants.each do |klass|
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

#This is a bit kludgy, but we don't want the Identifier subclasses to be loaded lazily
require 'identifier_subclasses/isbn'
require "identifier_subclasses/issn"
require 'identifier_subclasses/isrc'