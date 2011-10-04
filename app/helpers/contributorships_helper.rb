module ContributorshipsHelper
  def body_header(person, status)
    "#{link_to(h(person.display_name), person_path(person))}: #{status.capitalize} Contributorships".html_safe
  end

  def status_link(person, status, link_status)
    link_to_unless((status.downcase == link_status),
                   "#{link_status.capitalize} (#{person.contributorships.send(link_status).size})",
                   contributorships_path(:person_id => person.id, :status => link_status, :page => 1))
  end

  def romeo_color(row)
    row.color.present? ? row.color.downcase : 'unknown'
  end
end
