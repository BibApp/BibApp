#requires author name argument
xml.description h("My latest scholarly work")
@works.each do |work|
  xml << render('shared/rss_item', :work => work, :author_name => author_name)
end