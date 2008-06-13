class CitationImporter
  
  @@importers = Array.new
  
  class << self
    def inherited(subclass)
      @@importers << subclass unless @@importers.include?(subclass)
    end
    
    def importers
      @@importers
    end
  end
  
  def imps
    @imps
  end
  
  def citation_attribute_hashes(parsed_citations)
    hashes = Array.new
    parsed_citations.each do |c|
      hashes << citation_attribute_hash(c)
    end
    return hashes
  end
  
  def citation_attribute_hash(parsed_citation)
    importer_obj(parsed_citation.citation_type).generate_attribute_hash(parsed_citation)
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

Dir["#{File.expand_path(File.dirname(__FILE__))}/citation_importers/*_importer.rb"].each { |p| require p }