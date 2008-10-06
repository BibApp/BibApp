#
# Medline format parser
# 
# Parses a valid Medline text file (e.g. from PubMed)
# into a Ruby Hash.
# 
# All String parsing is done using "string".chars
# to ensure Unicode strings are parsed properly.
# See: http://api.rubyonrails.org/classes/ActiveSupport/CoreExtensions/String/Unicode.html
#
class MedlineParser < CitationParser
  
  def logger
    CitationParser.logger
  end
  
  #Determine if given data is Medline,
  # and if so, parse it!
  def parse_data(data)
    data = data.chars.dup
    data.chars.strip!
    
    if !data.nil?
      data.chars.gsub!("\r", "\n")
    end
    if !data.nil?
      data.chars.gsub!("\t", " ")
    end
    
    #Check if this is Medline format (looking for the PMID field)
    if not data.chars =~ /^PMID/
      return nil
    end
    logger.debug("This file is Medline format.")
    
    # Each record starts with a 'PMID' (PubMedID) field
    record = data.chars.split(/(?=^PMID\-)/)
    record.each do |rec|
      errorCheck = 1
      rec.chars.strip!
      cite = ParsedCitation.new(:medline)
      # Use a lookahead -- if the regex consumes characters, split() will
      # filter them out.
      rec.chars.split(/(?=^[A-Z][A-Z ]{3}\-\s+)/).each do |component|
        # Limit here in case we have a legit " - " in the string
        key, val = component.chars.split(/\s*\-\s*/, 2)
        key = key.chars.strip.downcase.to_sym
        # Skip components we can't parse
        next unless key and val
        errorCheck = 0
        
        # Add all values as an Array
        cite.properties[key] = Array.new if cite.properties[key].nil?
        cite.properties[key] << val.chars.strip
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