// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function populate_person_form(ldap_result_index, form) {
  var f = $(form);
  var res = ldap_results[ldap_result_index];
  f['person_first_name'].value = res.givenname;
  f['person_last_name'].value = res.sn;
  if (res.postaladdress) {
    var aparts = res.postaladdress.split('$');
    f['person_office_address_line_one'].value = aparts[0];
    if (aparts[1]) { f['person_office_address_line_two'].value = aparts[1]; }
  }
  if (res.mail) { f['person_email'].value = res.mail }
  if (res.telephonenumber) { f['person_phone'].value = res.telephonenumber  }
  if (res.postalcode) { f['person_office_zip'].value = res.postalcode }
  if (res.l) { f['person_office_city'].value = res.l }
  if (res.st) { f['person_office_state'].value = res.st }
}