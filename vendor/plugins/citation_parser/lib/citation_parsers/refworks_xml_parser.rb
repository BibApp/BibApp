class RefworksXmlParser < CitationParser
  require 'hpricot'
  require 'htmlentities'
    
  # Perform our initial parse of Citation Data,
  # using Hpricot to parse the Refworks XML format
  def parse(data)
    Hpricot.buffer_size = 204800
    xml = Hpricot.XML(data)
    row_count = (xml/:reference).collect{|ref| ref.to_s}
    if row_count.size < 1
      return nil
    end
  
    (xml/:reference).each { |ref|
      # add the citation to the database
      c = ParsedCitation.new(:refworks_xml)
      c.properties = param_hash(ref)
      @citations << c
    }
    
    @citations.each do |c|
      puts("\n\nCitation: #{c.inspect}\n\n")
    end
    
    puts("\nCitations Size: #{@citations.size}\n")
    puts("\nRefworksParser says:#{@citations.each{|c| c.inspect}}\n")
    
    #Return @citations
    @citations
  end
  
  def param_hash(xml)

    return {
      :ref_type => (xml/:rt).inner_html.to_a,
      :author_primary => (xml/:a1).collect{|a| a.inner_html},
      :author_secondary => (xml/:a2).collect{|a| a.inner_html},
      :title_primary => (xml/:t1).inner_html.to_a,
      :title_secondary => (xml/:t2).inner_html.to_a,
      :title_tertiary => (xml/:t3).inner_html.to_a,
      :keyword => (xml/:k1).collect{|k| k.inner_html},
      :pub_year => (xml/:yr).inner_html.to_a,
      :pub_date => (xml/:fd).inner_html.to_a,
      :periodical_full => (xml/:jf).inner_html.to_a,
      :periodical_abbrev => (xml/:jo).inner_html.to_a,
      :volume => (xml/:vo).inner_html.to_a,
      :issue => (xml/:is).inner_html.to_a,
      :start_page => (xml/:sp).inner_html.to_a,
      :other_pages => (xml/:op).inner_html.to_a,
      :edition => (xml/:ed).inner_html.to_a,
      :publisher => (xml/:pb).inner_html.to_a,
      :place_of_publication => (xml/:pp).inner_html.to_a,
      :issn_isbn => (xml/:sn).inner_html.to_a,
      :author_address_affiliations => (xml/:ad).inner_html.to_a,
      :accession_number => (xml/:an).inner_html.to_a,
      :language => (xml/:la).inner_html.to_a,
      :subfile_database => (xml/:sf).inner_html.to_a,
      :links => (xml/:lk).inner_html.to_a,
      :doi => (xml/:do).inner_html.to_a,
      :abstract => (xml/:ab).inner_html.to_a,
      :notes => (xml/:no).inner_html.to_a,
      :user_1 => (xml/:u1).inner_html.to_a,
      :user_2 => (xml/:u2).inner_html.split(/\||;/),
      :user_3 => (xml/:u3).inner_html.to_a,
      :user_4 => (xml/:u4).inner_html.to_a,
      :user_5 => (xml/:u5).inner_html.to_a,
      :original_data => xml
    }
  end 
end