#
# RefWorks XML format parser
#
# Parses a valid RefWorks XML file into a Ruby Hash.
#
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
  def parse_data(data)

    xml = Nokogiri::XML::Document.parse(data)

    #Check if this is Refworks XML format
    if xml.css('reference').count < 1
      return nil
    end
    logger.debug("\n\n* This file is the Refworks XML format.")

    # Each record is enclosed in a <reference> tag
    (xml.css('reference')).each do |ref|
      # create a new citation for each row in XML
      c = ParsedCitation.new(:refworks_xml)

      # map / parse all the properties
      props_hash = param_hash(ref)

      # decode any XML entities in properties (e.g. &apos; => ', &amp; => &, etc.)
      c.properties = decode_xml_entities(props_hash)

      @citations << c
    end

    logger.debug("\nCitations Size: #{@citations.size}\n")

    return @citations
  end

  def param_hash(xml)
    h = Hash.new
    #first handle standard fields
    {:ref_type => :rt, :author_primary => :a1, :author_secondary => :a2,
     :title_primary => :t1, :title_secondary => :t2, :title_tertiary => :t3,
     :keyword => :k1, :pub_year => :yr, :pub_date => :fd, :periodical_full => :jf,
     :periodical_abbrev => :jo, :volume => :vo, :issue => :is,
     :start_page => :sp, :other_pages => :op, :edition => :ed,
     :publisher => :pb, :place_of_publication => :pp, :issn_isbn => :sn,
     :author_address_affiliations => :ad, :accession_number => :an, :language => :la,
     :subfile_database => :sf, :links => :lk, :doi => :do, :abstract => :ab,
     :notes => :no, :user_1 => :u1, :user_2 => :u2, :user_3 => :u3,
     :user_4 => :u4, :user_5 => :u5}.each do |k, v|
      h[k] = xml.css(v.to_s).collect { |node| node.inner_html }
    end
    #then add original data
    h[:original_data] = xml.to_s
    h
  end
end