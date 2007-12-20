class RefworksXmlParser < CitationParser
  require 'rexml/document'
  
  def parse(data)
    begin 
      xml = REXML::Document.new(data)
    rescue
      return nil
    end
    
    return nil if xml.elements["//z:row"].nil?
  
    xml.elements.each("//z:row") { |ref|
      # add the citation to the database
      c = ParsedCitation.new(:refworks_xml)
      c.properties = param_hash(ref)
      @citations << c
    }
    @citations
  end
  
  def param_hash(xml)
    return {
      :reftype_id => xml.attributes["RefType"].to_i,
      :authors => xml.attributes["AuthorPrimary"],
      :affiliations => xml.attributes["AuthorSecondary"],
      :title_primary => xml.attributes["TitlePrimary"],
      :title_secondary => xml.attributes["TitleSecondary"],
      :title_tertiary => xml.attributes["TitleTertiary"],
      :keywords => xml.attributes["Keyword"],
      :pub_year => xml.attributes["PubYear"],
      :periodical_full => xml.attributes["PeriodicalFull"],
      :periodical_abbrev => xml.attributes["PeriodicalAbbrev"],
      :volume => xml.attributes["Volume"],
      :issue => xml.attributes["Issue"],
      :start_page => xml.attributes["StartPage"],
      :end_page => xml.attributes["OtherPages"],
      :edition =>  xml.attributes["Edition"],
      :publisher => xml.attributes["Publisher"],
      :place_of_publication => xml.attributes["PlaceOfPublication"],
      :issn_isbn => xml.attributes["ISSN_ISBN"],
      :availability => xml.attributes["Availability"],
      :author_address_affiliations => xml.attributes["Author_Address_Affiliation"],
      :accession_number => xml.attributes["AccessionNumber"],
      :language => xml.attributes["Language"],
      :classification => xml.attributes["Classification"],
      :subfile_database => xml.attributes["SubFile_Database"],
      :original_foreign_title => xml.attributes["OriginalForeignTitle"],
      :links => xml.attributes["Links"],
      :doi => xml.attributes["DOI"],
      :abstract => xml.attributes["Abstract"],
      :notes => xml.attributes["Notes"],
      :folder => xml.attributes["Folder"],
      :user_1 => xml.attributes["User1"],
      :user_2 => xml.attributes["User2"],
      :user_3 => xml.attributes["User3"],
      :user_4 => xml.attributes["User4"],
      :user_5 => xml.attributes["User5"],
      :call_number => xml.attributes["CallNumber"],
      :database_name => xml.attributes["DatabaseName"],
      :data_source => xml.attributes["DataSource"],
      :identifying_phrase => xml.attributes["IdentifyingPhrase"],
      :retrieved_date => xml.attributes["RetrievedDate"],
      :shortened_title => xml.attributes["ShortenedTitle"],
      :text_attributes => xml.attributes["TextAttributes"],
      :url => xml.attributes["URL"],
      :sponsoring_library => xml.attributes["SponsoringLibrary"],
      :sponsoring_library_location => xml.attributes["SponsoringLibraryLocation"],
      :cited_refs => xml.attributes["CitedRefs"],
      :website_title => xml.attributes["WebsiteTitle"],
      :website_editor => xml.attributes["WebsiteEditor"],
      :website_version => xml.attributes["WebsiteVersion"],
      :pub_date_electronic => xml.attributes["PubDateElectronic"],
      :source_type => xml.attributes["SourceType"],
      :over_flow => xml.attributes["OverFlow"],
      :objects => xml.attributes["Objects"]
    }
  end 
end