#
# RIS format parser
# 
# Parses a valid RIS text file into a Ruby Hash.
# 
# All String parsing is done using String.mb_chars
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
    risdata.strip!
    risdata = risdata.mb_chars.dup
    risdata.mb_chars.strip!
    risdata.mb_chars.gsub!("\r", "\n")
    
    #determine if this is RIS data or not (looking for the 'ER' field)
    if not risdata.mb_chars =~ /^ER  \-/
      return nil
    end
    logger.debug("\n\n* This file is RIS format.")
    
    #Individual records are separated by 'ER' field
    records = risdata.mb_chars.split(/^ER\s.*/i)
    
    records.each_with_index do |rec, i|
      errorCheck = 1
      rec.mb_chars.strip!
      cite = ParsedCitation.new(:ris)

      # Save original data for inclusion in final hash
      cite.properties[:original_data] = rec

      # Use a lookahead -- if the regex consumes characters, split() will
      # filter them out.
      # Keys (or 'tags') are specified by the following regex.
      # See spec at http://www.refman.com/support/risformat_fields_01.asp
        
      logger.debug("\nParsing...")
      
      rec.mb_chars.split(/(?=^[A-Z][A-Z0-9]\s{2}\-\s+)/).each do |component|
        # Limit here in case we have a legit " - " in the string
        key, val = component.mb_chars.split(/\s+\-\s+/, 2)
        
        # Rails 2.3.3 requires mb_chars, and don't call to_sym on empty string!
        key = key.mb_chars.downcase.strip.to_sym if !key.mb_chars.downcase.strip.empty?
        
        # Skip components we can't parse
        next unless key and val
        errorCheck = 0
        
        # Add all values as an Array
        cite.properties[key] = Array.new if cite.properties[key].nil?
        cite.properties[key] << val.mb_chars.strip
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