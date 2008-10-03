class RisParser < CitationParser
  
  def logger
    CitationParser.logger
  end
  
  def parse(risdata)
    risdata = risdata.dup
    risdata.strip!
    risdata.gsub!("\r", "\n")
    
    #determine if this is RIS data or not
    if not risdata =~ /^ER  \-/
      return nil
    end
    logger.debug("This file is RIS format.")
    
 #TODO make sure we escape all neccessary characters   
 #   risdata.gsub!("�", "-").gsub!("�", "y").gsub!("�", "'")
    risdata = risdata.split(/^ER\s.*/i)
    risdata.each do |rec|
      errorCheck = 1
      rec.strip!  
      cite = ParsedCitation.new(:ris)
      # Save original data for inclusion in final hash
      cite.properties[:original_data] = rec
      # Use a lookahead -- if the regex consumes characters, split() will
      # filter them out.
      # Keys (or 'tags') are specified by the following regex.
      # See spec at http://www.refman.com/support/risformat_fields_01.asp
      rec.split(/(?=^[A-Z][A-Z0-9]\s{2}\-\s+)/).each do |component|
        # Limit here in case we have a legit " - " in the string
        key, val = component.split(/\s+\-\s+/, 2)
        key = key.strip.downcase.to_sym
        # Skip components we can't parse
        
        next unless key and val
        errorCheck = 0
        cite.properties[key] = Array.new if cite.properties[key].nil?
        cite.properties[key] << val.strip
      end

      # The following error should only occur if no part of the citation
      # is consistent with the RIS format. 
      if errorCheck == 1
        logger.error("\n There was an error on the following citation:\n #{rec}\n\n")
      else
        @citations << cite
      end
    end
  
 
    @citations
  end  
end