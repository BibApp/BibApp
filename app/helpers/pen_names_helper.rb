module PenNamesHelper
  def body_header(person)
    "#{link_to(h(person.display_name), person_path(person))}: #{PenName.model_name.human_pl}".html_safe
  end

end
