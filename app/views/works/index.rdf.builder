rdf_document_on(xml) do
  @works.each do |w|
    work = Work.find(w['pk_i'])
    (xml << render(:partial => "shared/package", :locals => {:work => work})) if work
  end
  if @has_next_page
    @page = @page == 0 ? 1 : @page
    xml.link({:rel => "next", :href => "#{works_url()}.rdf?page=#{@page.to_i+1}"})
  end
end
