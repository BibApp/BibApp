#
# RIS format parser
# 
# Parses a valid RIS text file into a Ruby Hash.
# 
# All String parsing is done using String.chars
# to ensure Unicode strings are parsed properly.
# See: http://api.rubyonrails.org/classes/ActiveSupport/CoreExtensions/String/Unicode.html
#
class RisParser < CitationParser
  
  def logger
    CitationParser.logger
  end
  
  #Determine if given data is RIS,
  # and if so, parse it!
  def parse_data(risdata)
    risdata = risdata.chars.dup
    risdata.chars.strip!
    risdata.chars.gsub!("\r", "\n")
    
    #determine if this is RIS data or not (looking for the 'ER' field)
    if not risdata.chars =~ /^ER  \-/
      return nil
    end
    logger.debug("This file is RIS format.")
    
    #Individual records are separated by 'ER' field
    records = risdata.chars.split(/^ER\s.*/i)
    records.each do |rec|
      errorCheck = 1
      rec.chars.strip!  
      cite = ParsedCitation.new(:ris)
      # Save original data for inclusion in final hash
      cite.properties[:original_data] = rec
      # Use a lookahead -- if the regex consumes characters, split() will
      # filter them out.
      # Keys (or 'tags') are specified by the following regex.
      # See spec at http://www.refman.com/support/risformat_fields_01.asp
      rec.chars.split(/(?=^[A-Z][A-Z0-9]\s{2}\-\s+)/).each do |component|
        # Limit here in case we have a legit " - " in the string
        key, val = component.chars.split(/\s+\-\s+/, 2)
        key = key.chars.strip.downcase.to_sym
        
        # Skip components we can't parse
        next unless key and val
        errorCheck = 0
        
        # Add all values as an Array
        cite.properties[key] = Array.new if cite.properties[key].nil?
        cite.properties[key] << val.chars.strip
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