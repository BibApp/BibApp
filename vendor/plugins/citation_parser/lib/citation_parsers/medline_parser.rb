#
# Medline format parser
#
# Parses a valid Medline text file (e.g. from PubMed)
# into a Ruby Hash.
#
class MedlineParser < CitationParser

  def logger
    CitationParser.logger
  end

  #Determine if given data is Medline,
  # and if so, parse it!
  def parse_data(data)
    data = data.dup.strip!

    unless data.blank?
      data.gsub!("\r", "\n")
    end
    unless data.blank?
      data.gsub!("\t", " ")
    end

    #Check if this is Medline format (looking for the PMID field)
    unless data =~ /^PMID/
      return nil
    end
    logger.debug("\n\n* This file is Medline format.")

    # Each record starts with a 'PMID' (PubMedID) field
    record = data.split(/(?=^PMID\-)/)
    record.each do |rec|
      errorCheck = 1
      rec.strip!
      cite = ParsedCitation.new(:medline)
      # Use a lookahead -- if the regex consumes characters, split() will
      # filter them out.
      rec.split(/(?=^[A-Z][A-Z ]{3}\-\s+)/).each do |component|
        # Limit here in case we have a legit " - " in the string
        key, val = component.split(/\s*\-\s*/, 2)

        # Don't call to_sym on empty string!
        key = key.downcase.strip.to_sym unless key.downcase.strip.empty?

        # Skip components we can't parse
        next unless key and val
        errorCheck = 0

        # Add all values as an Array
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