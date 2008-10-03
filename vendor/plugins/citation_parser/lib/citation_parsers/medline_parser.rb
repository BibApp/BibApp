class MedlineParser < CitationParser
  
  def logger
    CitationParser.logger
  end
  
  def parse(data)
    data = data.dup
    data.strip!
    
    if !data.nil?
      data.gsub!("\r", "\n")
    end
    if !data.nil?
      data.gsub!("\t", " ")
    end
    if not data =~ /^PMID/
      return nil
    end
    logger.debug("This file is Medline format.")
    
    data = data.split(/(?=^PMID\-)/)
    data.each do |rec|
      errorCheck = 1
      rec.strip!
      cite = ParsedCitation.new(:medline)
      # Use a lookahead -- if the regex consumes characters, split() will
      # filter them out.
      rec.split(/(?=^[A-Z][A-Z ]{3}\-\s+)/).each do |component|
        # Limit here in case we have a legit " - " in the string
        key, val = component.split(/\s*\-\s*/, 2)
        key = key.strip.downcase.to_sym
        # Skip components we can't parse
        next unless key and val
        errorCheck = 0
        cite.properties[key] = Array.new if cite.properties[key].nil?
        cite.properties[key] << val.strip
        end
      # Save original data for inclusion in final hash
      cite.properties[:original_data] = rec
      
      # The following error should only occur if no part of the citation
      # is consistent with the Medline format. 
      if errorCheck == 1
        logger.error("\n There was an error on the following citation:\n #{rec}\n\n")
      else
        @citations << cite
      end
      
    end
    
    
    @citations
  end
  

  
end