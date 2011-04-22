module PeopleHelper
  #Require namecase gem, if it's defined.  
  # This allows us to make solr-ruby a Gem Dependency, as suggested in this blog:
  # http://www.webficient.com/2008/7/11/rails-gem-dependencies-and-plugin-errors
  require 'namecase' if defined? NameCase
  
  def pretty_ldap_person(ldap_result)
    NameCase.new("#{ldap_result[:givenname]} #{ldap_result[:sn]} ") +
    pretty_ldap_dept(ldap_result)
  end
  
  def pretty_ldap_dept(ldap_result)
    ar = Array.new
    ar << ldap_result[:title].titleize unless ldap_result[:title].blank?
    ar << ldap_result[:ou].titleize unless ldap_result[:ou].blank?
    ar.size > 0 ? "(#{ar.join(', ')})" : ""
  end
  
end
