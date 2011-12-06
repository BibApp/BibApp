rss_document_on(xml) do
  xml.channel do
    xml.title t('personalize.university_short_name') + ": " + @person.name
    xml.link person_url(:only_path => false, :id => @person.id)
    xml.image h($APPLICATION_URL + @person.image_url)
    xml << render('shared/rss_works', :author_name => @person.name)
  end
end