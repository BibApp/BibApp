#
# CitationImporter plugin
#
# This class calls our defined Citation Importers to actually
# generate a valid attribute hash for the BibApp database:
# http://bibapp.googlecode.com/
#
class CitationImporter
  #Must require ActiveRecord so we have access to Rails Unicode tools
  # See: http://api.rubyonrails.org/classes/ActiveSupport/CoreExtensions/String/Unicode.html
  require 'active_record'

  @@importers = Array.new

  class << self
    # Callback method for subclasses
    # Adds all subclasses to our array of importers
    def inherited(subclass)
      @@importers << subclass unless @@importers.include?(subclass)
    end

    def importers
      @@importers
    end

    def logger
      #Use RAILS_DEFAULT_LOGGER by default for all logging
      @@logger ||= Rails.logger
    end
  end

  def imps
    @imps
  end

  def citation_attribute_hashes(parsed_citations)
    parsed_citations.collect do |c|
      citation_attribute_hash(c)
    end
  end

  # Generate a valid BibApp attribute Hash from a parsed citation
  def citation_attribute_hash(parsed_citation)

    importer = importer_obj(parsed_citation.citation_type)

    #generate our hash (performed by BaseImporter)
    hash = importer.generate_attribute_hash(parsed_citation) if importer.respond_to?(:generate_attribute_hash)

    return hash
  end

  def importer_obj(type)
    @imps[type]
  end

  def initialize
    # We instantiate subclasses here, so we must prevent
    # infinite recursion as subclasses call super.initialize
    return unless self.class == CitationImporter
    @imps = Hash.new
    klasses = @@importers.dup
    klasses.each do |klass|
      formats = klass.import_formats
      importer = klass.new
      formats.each do |f|
        @imps[f] = importer
      end
    end
  end

end

#Load BaseImporter first, then all format-specific citation importers.
require "#{File.expand_path(File.dirname(__FILE__))}/base_importer.rb"
Dir["#{File.expand_path(File.dirname(__FILE__))}/citation_importers/*_importer.rb"].each { |p| require p }