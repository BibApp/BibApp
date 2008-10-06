#
# RefWorks Deprecated XML format parser
# 
# Parses a valid RefWorks XML (Deprecated) file into a Ruby Hash.
# As RefWorks has deprecated this older XML format,
# it is recommended to now use the new RefWorks XML format
# (supported by the RefworksXmlParser).
# 
# XML parsing is handled by Hpricot:
#   http://code.whytheluckystiff.net/hpricot/
#   
# All String parsing is done using String.chars
# to ensure Unicode strings are parsed properly.
# See: http://api.rubyonrails.org/classes/ActiveSupport/CoreExtensions/String/Unicode.html
#
class RefworksDeprecatedXmlParser < BaseXmlParser
 
  def logger
    CitationParser.logger
  end
  
  # Perform our initial parse of Citation Data,
  # using Hpricot to parse the Refworks XML format
  def parse_data(data)
#    if data != nil
#      data.gsub("�", "-").gsub("�", "y").gsub("�", "'")
#    end

    xml = Hpricot.XML(data)
    
    #Check if this is Refworks Deprecated XML format
    row_count = (xml/'z:row').collect{|ref| ref.to_s}
    if row_count.size < 1
      return nil
    end
    logger.debug("This file is the Refworks Deprecated XML format.")
  
    # Each record is enclosed in a <z:row> tag
    (xml/'z:row').each { |ref|
      # create a new citation for each row in XML
      c = ParsedCitation.new(:refworks_deprecated_xml)

      # map / parse all the properties
      props_hash = param_hash(ref)
      
      # decode any XML entities in properties (e.g. &apos; => ', &amp; => &, etc.)
      c.properties = decode_xml_entities(props_hash)
      
      @citations << c
    }
    
  
    return @citations
  end
  
  def param_hash(xml)

    return {
      :ref_type => xml[:RefType].to_a,
      :author_primary => xml[:AuthorPrimary].chars.split("|"),
      :author_secondary => xml[:AuthorSecondary].chars.split("|"),
      :title_primary => xml[:TitlePrimary].to_a,
      :title_secondary => xml[:TitleSecondary].to_a,
      :title_tertiary => xml[:TitleTertiary].to_a,
      :keyword => xml[:Keyword].chars.split(/\||;/).each{|k| k.chars.strip!},
      :pub_year => xml[:PubYear].to_a,
      :periodical_full => xml[:PeriodicalFull].to_a,
      :periodical_abbrev => xml[:PeriodicalAbbrev].to_a,
      :volume => xml[:Volume].to_a,
      :issue => xml[:Issue].to_a,
      :start_page => xml[:StartPage].to_a,
      :other_pages => xml[:OtherPages].to_a,
      :edition =>  xml[:Edition].to_a,
      :publisher => xml[:Publisher].to_a,
      :place_of_publication => xml[:PlaceOfPublication].to_a,
      :issn_isbn => xml[:ISSN_ISBN].to_a,
      :availability => xml[:Availability].to_a,
      :author_address_affiliations => xml[:Author_Address_Affiliation].to_a,
      :accession_number => xml[:AccessionNumber].to_a,
      :language => xml[:Language].to_a,
      :classification => xml[:Classification].to_a,
      :subfile_database => xml[:SubFile_Database].to_a,
      :original_foreign_title => xml[:OriginalForeignTitle].to_a,
      :links => xml[:Links].chars.split("|"),
      :doi => xml[:DOI].chars.split("|"),
      :abstract => xml[:Abstract].to_a,
      :notes => xml[:Notes].to_a,
      :folder => xml[:Folder].to_a,
      :user_1 => xml[:User1].to_a,
      :user_2 => xml[:User2].chars.split(/\||;/).each{|k| k.chars.strip!},
      :user_3 => xml[:User3].to_a,
      :user_4 => xml[:User4].to_a,
      :user_5 => xml[:User5].to_a,
      :call_number => xml[:CallNumber].to_a,
      :database_name => xml[:DatabaseName].to_a,
      :data_source => xml[:DataSource].to_a,
      :identifying_phrase => xml[:IdentifyingPhrase].to_a,
      :retrieved_date => xml[:RetrievedDate].to_a,
      :shortened_title => xml[:ShortenedTitle].to_a,
      :text_attributes => xml[:TextAttributes].to_a,
      :url => xml[:URL].chars.split("|"),
      :sponsoring_library => xml[:SponsoringLibrary].to_a,
      :sponsoring_library_location => xml[:SponsoringLibraryLocation].to_a,
      :cited_refs => xml[:CitedRefs].to_a,
      :website_title => xml[:WebsiteTitle].to_a,
      :website_editor => xml[:WebsiteEditor].to_a,
      :website_version => xml[:WebsiteVersion].to_a,
      :pub_date_electronic => xml[:PubDateElectronic].to_a,
      :source_type => xml[:SourceType].to_a,
      :over_flow => xml[:OverFlow].to_a,
      :objects => xml[:Objects].to_a,
      :original_data => xml.to_s
    }
  end 
end