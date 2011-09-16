rdf_document_on(xml) do
  (xml << render(:partial => "package", :locals => {:person => @person})) if @person
end
