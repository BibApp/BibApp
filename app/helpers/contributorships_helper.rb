module ContributorshipsHelper
  def contributorships_body_header(person, status)
    "#{link_to(h(person.display_name), person_path(person))}: #{status.capitalize} Contributorships".html_safe
  end
end
