require 'rbibtex.tab'

class BibtexParser < CitationParser
  
  def parse(data)
    bp = BibTeX::Parser.new
    records = nil
    begin
      records = bp.parse(data)
    rescue
      return nil
    end
    return nil if records.nil?
    
    records.each do |rec|
      cite = ParsedCitation.new(:bibtex)
      props = cite.properties
      props[:type] = [rec.type]
      props[:key] = [rec.key]
      rec.properties.each do |key, val|
        props[key] = Array.new if props[key].nil?
        if key == :author
          val_a = val.split("and")
          val_a.each do |v|
            props[key] << v.strip
          end
        else
          props[key] << val.strip
        end
      end
      @citations << cite
    end
    @citations
  end
end