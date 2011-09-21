rdf_document_on(xml) do
  xml << (render(:partial => 'shared/package', :locals => {:work => @work}))
end
