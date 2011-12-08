# METS Metadata Wrapper, which contains metadata
# in EPrints DC XML Schema (epdcx) - As necessary for SWORD
# See: http://www.ukoln.ac.uk/repositories/digirep/index/Eprints_Application_Profile

#Require personalize.rb for Abstracts and Keywords
require 'config/personalize.rb'

xml.mdWrap(:LABEL=>"SWORD Metadata - EPrints DC XML schema", :MDTYPE=>"OTHER", :OTHERMDTYPE=>"EPDCX", :MIMETYPE=>"text/xml") do
  xml.xmlData do
    xml.epdcx(:descriptionSet, 'epdcx:resourceId'=>"sword-mets-epdcx-#{work.id}") do
      xml.epdcx(:description, 'epdcx:resourceId'=>"sword-mets-epdcx-#{work.id}") do
        xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/elements/1.1/type", 'epdcx:valueURI'=>"http://purl.org/eprint/entityType/ScholarlyWork")
        xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/elements/1.1/title" ) do
          xml.epdcx(:valueString, encode_for_xml(work.title_primary))
        end
        work.tags.each do |tag|
          xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/elements/1.1/subject") do
            xml.epdcx(:valueString, encode_for_xml(tag.name))
          end
        end
        if work.abstract.present? and $EXPORT_ABSTRACTS_AND_KEYWORDS
          xml.epdcx(:statement,  'epdcx:propertyURI'=>"http://purl.org/dc/terms/abstract" ) do
            xml.epdcx(:valueString, encode_for_xml(work.abstract))
          end
        end
        work.work_name_strings.where(:role => work.creator_role).includes(:name_string).each do |wns|
          xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/elements/1.1/creator") do
            xml.epdcx(:valueString, encode_for_xml(wns.name_string.name))
          end
        end
        xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/eprint/terms/isExpressedAs", 'epdcx:valueRef'=>"sword-mets-expr-#{work.id}")
      end
      xml.epdcx(:description, 'epdcx:resourceId'=>"sword-mets-expr-#{work.id}") do
        xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/elements/1.1/type", 'epdcx:valueURI'=>"http://purl.org/eprint/entityType/Expression")
        if work.title_secondary.present?
          xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/elements/1.1/title") do
            xml.epdcx(:valueString, encode_for_xml(work.title_secondary))
          end
        end
        if work.title_tertiary.present?
          xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/elements/1.1/title") do
            xml.epdcx(:valueString, encode_for_xml(work.title_tertiary))
          end
        end
        if work.notes.present?
          xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/elements/1.1/description" ) do
            xml.epdcx(:value_string, encode_for_xml(work.notes))
          end
        end
        if work.publication_date_year
          xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/terms/available") do
            xml.epdcx(:valueString, {'epdcx:sesURI'=>"http://purl.org/dc/terms/W3CDTF"}, work.publication_date_year)
          end
        end
        if work.language
          xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/elements/1.1/language", 'epdcx:vesURI'=>"http://purl.org/dc/terms/RFC3066") do
            xml.epdcx(:valueString, encode_for_xml(work.language))
          end
        end
        if work.type_uri.present?
          if work.type_uri.include?('eprint/type')
            xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/elements/1.1/type", 'epdcx:vesURI'=>"http://purl.org/eprint/terms/Type", 'epdcx:valueURI'=>"#{work.type_uri}")
          else
            xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/elements/1.1/type", 'epdcx:vesURI'=>"http://purl.org/dc/dcmitype/", 'epdcx:valueURI'=>"#{work.type_uri}")
          end
        end
        if work.copyright_holder
          xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/eprint/terms/copyrightHolder" ) do
            xml.epdcx(:valueString, encode_for_xml(work.copyright_holder))
          end
        end
        work.work_name_strings.where(:role => work.contributor_role).includes(:name_string).each do |wns|
          xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://www.loc.gov/loc.terms/relators/EDT") do
            xml.epdcx(:valueString, encode_for_xml(wns.name_string.name))
          end
        end
        xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/terms/bibliographicCitation" ) do
          xml.epdcx(:valueString, encode_for_xml(work.to_s))
          xml << (render(:partial => 'works/epdcx_openurl.mets', :locals => {:work => work}))
        end
        work.attachments.each do |att|
          xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/eprint/terms/isManifestedAs", 'epdcx:valueRef'=>"sword-mets-manifest-#{att.id}" )
        end
      end
      work.attachments.each do |att|
        filepath = filenames_only ? att.filename : att.public_url(request)
        xml.epdcx(:description, 'epdcx:resourceId'=>"sword-mets-manifest-#{att.id}" ) do
          xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/elements/1.1/type", 'epdcx:valueURI'=>"http://purl.org/eprint/entityType/Manifestation")
          xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/elements/1.1/format", 'epdcx:valueURI'=>"http://purl.org/dc/terms/IMT") do
            xml.epdcx(:valueString, encode_for_xml(att.content_type))
          end
          if work.publisher
            xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/elements/1.1/publisher") do
              xml.epdcx(:valueString, encode_for_xml(work.publisher.authority.name))
            end
          end
          xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/eprint/terms/isAvailableAs", 'epdcx:valueURI'=> filepath)
        end
        xml.epdcx(:description, 'epdcx:resourceURI'=>filepath ) do
          xml.epdcx(:statement, 'epdcx:propertyURI'=>"http://purl.org/dc/elements/1.1/type", 'epdcx:valueURI'=>"http://purl.org/eprint/entityType/Copy")
        end
      end
    end
  end
end