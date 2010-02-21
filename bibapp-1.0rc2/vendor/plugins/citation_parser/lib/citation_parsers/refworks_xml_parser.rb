#
# RefWorks XML format parser
# 
# Parses a valid RefWorks XML file into a Ruby Hash.
# 
# XML parsing is handled by Hpricot:
#   http://code.whytheluckystiff.net/hpricot/
#   
# All String parsing is done using String.mb_chars
# to ensure Unicode strings are parsed properly.
# See: http://api.rubyonrails.org/classes/ActiveSupport/CoreExtensions/String/Unicode.html
#
class RefworksXmlParser < BaseXmlParser
  
  def logger
    CitationParser.logger
  end
  
  # Perform our initial parse of Citation Data,
  # using Hpricot to parse the Refworks XML format
  def parse_data(data)
   
    xml = Hpricot.XML(data)
    
    #Check if this is Refworks XML format
    row_count = (xml/:reference).collect{|ref| ref.to_s} 
    if row_count.size < 1
      return nil
    end
    logger.debug("\n\n* This file is the Refworks XML format.")
  
    # Each record is enclosed in a <reference> tag
    (xml/:reference).each { |ref|
      # create a new citation for each row in XML
      c = ParsedCitation.new(:refworks_xml)

      # map / parse all the properties
      props_hash = param_hash(ref)
      
      # decode any XML entities in properties (e.g. &apos; => ', &amp; => &, etc.)
      c.properties = decode_xml_entities(props_hash)
      
      @citations << c  
    }
    
    logger.debug("\nCitations Size: #{@citations.size}\n")
    
    return @citations
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
      :user_2 => (xml/:u2).inner_html.mb_chars.split(/\||;/),
      :user_3 => (xml/:u3).inner_html.to_a,
      :user_4 => (xml/:u4).inner_html.to_a,
      :user_5 => (xml/:u5).inner_html.to_a,
      :original_data => xml.to_s
    }
  end 
end