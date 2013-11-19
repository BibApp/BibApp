rss_document_on(xml) do
  xml.channel do
    xml.title t('personalize.university_short_name') + ": " + @group.name
    xml.link group_url(:only_path => false, :id => @group.id)
    xml.image h($APPLICATION_URL + $APPLICATION_LOGO)
    xml << render('shared/rss_works', :author_name => @group.name)
  end
end

