xml.instruct!
xml.mets(:OBJID=>"sword-mets", :LABEL=>"BibApp SWORD package", :PROFILE=>"DSpace METS SIP Profile 1.0", :xmlns=>"http://www.loc.gov/METS/", 'xmlns:xlink'=>"http://www.w3.org/1999/xlink", 'xmlns:xsi'=>"http://www.w3.org/2001/XMLSchema-instance", 'xsi:schemaLocation'=>"http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd", 'xmlns:epdcx' => 'http://purl.org/eprint/epdcx/2006-11-16/') do
  xml.metsHdr(:CREATEDATE => DateTime.now.to_s(:xsd)) do
    xml.agent(:ROLE=>"CREATOR", :TYPE=>"OTHER") do
      xml.name("BibApp")
    end
  end
  xml.dmdSec(:ID => "sword-mets-dmd-#{work.id}", :CREATED => work.created_at.to_s(:xsd)) do
    xml << (render(:partial => 'works/epdcx.mets', :locals => {:work => work, :filenames_only => filenames_only}))
  end
  xml.fileSec do
    xml.fileGrp(:ID=>"sword-mets-fgrp-#{work.id}", :USE=>"CONTENT") do
      work.attachments.each do |att|
        xml.file(:ID=>"sword-mets-file-#{att.id}", :MIMETYPE=>att.content_type, :SIZE=>att.size) do
          if filenames_only
            xml.FLocat(:LOCTYPE=>"URL", "xlink:href"=>att.filename)
          else
            xml.FLocat(:LOCTYPE=>"URL", "xlink:href"=>att.public_url(request))
          end
        end
      end
    end
  end
  xml.structMap(:ID=>"sword-mets-struct-#{work.id}", :TYPE=>"LOGICAL") do
    xml.div(:ID=>"sword-mets-struct-div-#{work.id}", :DMDID=>"sword-mets-dmd-#{work.id}", :TYPE=>"SWORD Object") do
      work.attachments.each do |att|
        xml.div(:ID=>"sword-mets-struct-file-#{att.id}", :TYPE=>"FILE") do
          xml.fptr(:FILEID=>"sword-mets-file-#{att.id}")
        end
      end
    end
  end
end