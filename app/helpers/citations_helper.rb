module CitationsHelper
  # TODO: Make these live again, in the land of XML.

  def to_mets_xml
    xml = Builder::XmlMarkup.new(:prefix => "METS", :indent => 2)

    # Use tag! method for namespace support
      xml.tag!("METS:mets",
                  :LABEL                      => "#{title_primary}",
                  :OBJID                      => "demo:" + id.to_s,
                  :PROFILE                    => "TEST_IMAGE",
                  :TYPE                       => "FedoraObject",
                  "xmlns:METS".to_sym         => "http://www.loc.gov/METS/",
                  "xmlns:audit".to_sym        => "info:fedora/fedora-system:def/audit#",
                  "xmlns:foxml".to_sym        => "info:fedora/fedora-system:def/foxml#",
                  "xmlns:xlink".to_sym        => "http://www.w3.org/TR/xlink",
                  "xmlns:xsi".to_sym          => "http://www.w3.org/2001/XMLSchema-instance",
                  "xsi:schemaLocation".to_sym => "http://www.loc.gov/METS/ http://www.fedora.info/definitions/1/0/mets-fedora-ext.xsd" ){
        xml.tag!("METS:metsHdr", :RECORDSTATUS => "A")
        xml.tag!("METS:amdSec",  :ID => "DC", :STATUS => "A"){
          xml.tag!("METS:techMD", :ID => "DC." + id.to_s){
            xml.tag!("METS:mdWrap", :LABEL => "Default Dublin Core Record", :MDTYPE => "OTHER", :MIMETYPE => "text/xml", :OTHERMDTYPE => "UNSPECIFIED"){
              xml.tag!("METS:xmlData"){
                xml.tag!("oai_dc:dc",
                  "xmlns:oai_dc".to_sym => "http://www.openarchives.org/OAI/2.0/oai_dc/",
                  "xmlns:dc".to_sym => "http://purl.org/dc/elements/1.1/"
                ){
                  xml.tag!("dc:title"){xml.text! "#{title_primary}"}
                  author_array.each do |a|
                    xml.tag!("dc:contributor"){xml.text! "#{a}"}
                  end
                  xml.tag!("dc:description"){xml.text! "#{abstract}"}
                  xml.tag!("dc:date"){xml.text! "#{pub_year}"}
                  xml.tag!("dc:publisher"){xml.text! "#{publisher}"}
                  xml.tag!("dc:description"){xml.text! "This material is presented to ensure timely dissemination of scholarly and technical work. Copyright and all rights therein are retained by authors or by other copyright holders. All persons copying this information are expected to adhere to the terms and constraints invoked by each author's copyright. In most cases, these works may not be reposted without the explicit permission of the copyright holder."}
                  xml.tag!("dc:identifier", :qualifier => "citation"){xml.text! "#{format_citation_apa_to_s}"}
                  xml.tag!("dc:format", :qualifier => "mimetype"){xml.text! "application/pdf"}
                }
              }
            }  
          }
        }
        xml.tag!("METS:amdSec", :ID => "RELS-EXT", :STATUS => "A"){
          xml.tag!("METS:techMD", :ID => "RELS-EXT." + id.to_s){
            xml.tag!("METS:mdWrap",
                :LABEL        => "Fedora Object-to-Object Relationship Metadata",
                :MDTYPE       => "OTHER",
                :MIMETYPE     => "text/xml",
                :OTHERMDTYPE  => "UNSPECIFIED"){
                
              xml.tag!("METS:xmlData"){
                xml.tag!("rdf:RDF",
                   "xmlns:dc".to_s => "http://purl.org/dc/elements/1.1/",
                   "xmlns:fedora".to_s => "info:fedora/fedora-system:def/relations-external#",
                   "xmlns:myns".to_s => "http://www.nsdl.org/ontologies/relationships#",
                   "xmlns:oai_dc".to_s => "http://www.openarchives.org/OAI/2.0/oai_dc/",
                   "xmlns:rdf".to_s => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
                   "xmlns:rdfs".to_s => "http://www.w3.org/2000/01/rdf-schema#"){
                 xml.tag!("rdf:Description", "rdf:about".to_s => "info:fedora/demo:" + id.to_s){
                   xml.tag!("fedora:isMemberOfCollection", "rdf:resource".to_s => "info:fedora/test:collection1")
                   xml.tag!("myns:isPartOf", "rdf:resource".to_s => "info:fedora/mystuff:1")
                 }
                }
              }
            }
          }
        }
      }
  end
end
