class MedlineParser < CitationParser
  
  def parse(data)
    data = data.dup
    data.strip!
    data.gsub!("\r", "\n")
    if not data =~ /^PMID/
      return nil
    end
    data = data.split(/(?=^PMID\-)/)
    data.each do |rec|
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
        cite.properties[key] = Array.new if cite.properties[key].nil?
        cite.properties[key] << val.strip
      end

      # Map original data for inclusion in database
      cite.properties["original_data"] = rec
      @citations << cite
    end
    
    puts("\nCitations Size: #{@citations.size}\n")
    puts("\nMEDLINEParser says:#{@citations.each{|c| c.inspect}}\n")
    
    @citations
  end
  

  
end