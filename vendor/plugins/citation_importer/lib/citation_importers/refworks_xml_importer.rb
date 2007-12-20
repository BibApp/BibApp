class RefworksXmlImporter < CitationImporter
  class << self
    def import_formats
      [:refworks_xml]
    end
  end
  
  def generate_attribute_hash(parsed_citation) 
    return false if !self.class.import_formats.include?(parsed_citation.citation_type)
    
    return parsed_citation.properties
  end
end