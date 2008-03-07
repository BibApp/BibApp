class RisParser < CitationParser
  
  def parse(risdata)
    risdata = risdata.dup
    risdata.strip!
    risdata.gsub!("\r", "\n")
    if not risdata =~ /^ER  \-/
      return nil
    end
    
    risdata = risdata.split(/^ER\s.*/i)
    risdata.each do |rec|
      rec.strip!
      cite = ParsedCitation.new(:ris)
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
        cite.properties[key] = Array.new if cite.properties[key].nil?
        cite.properties[key] << val.strip
      end

      # Map original data for inclusion in database
      cite.properties["original_data"] = rec
      @citations << cite
    end
    @citations
  end  
end