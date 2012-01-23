module ContributorshipsHelper
  def body_header(person, status)
    t('common.contributorships.index_title_html', :display_name => link_to(h(person.display_name), person_path(person)),
      :status => t("common.contributorships.#{status}").capitalize)
  end

  def status_link(person, status, link_status)
    link_to_unless((status.downcase == link_status),
                   "#{t("common.contributorships.#{link_status}")} (#{person.contributorships.send(link_status).size})",
                   contributorships_path(:person_id => person.id, :status => link_status, :page => 1))
  end

  def romeo_color(row)
    t("personalize.sherpa_colors.#{row.color.self_or_blank_default('unknown').downcase}.name")
  end

end
