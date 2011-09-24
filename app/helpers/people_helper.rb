require 'namecase'
module PeopleHelper

  def pretty_ldap_person(ldap_result)
    NameCase.nc("#{ldap_result[:givenname]} #{ldap_result[:sn]} ") +
            pretty_ldap_dept(ldap_result)
  end

  def pretty_ldap_dept(ldap_result)
    ar = Array.new
    ar << ldap_result[:title].titleize unless ldap_result[:title].blank?
    ar << ldap_result[:ou].titleize unless ldap_result[:ou].blank?
    ar.size > 0 ? "(#{ar.join(', ')})" : ""
  end

  def edit_header(person)
    "#{link_to(h(@person.display_name), person_path(@person))}: Personal Info".html_safe
  end

end
