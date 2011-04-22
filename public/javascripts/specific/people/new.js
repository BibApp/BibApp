var ldap_results = decode_js_data_div('ldap_results')

function populate_person_form(ldap_result_index) {
  var f = $('new_person');
  var res = ldap_results[ldap_result_index];

  f['person_uid'].value = res.uid;
  f['person_first_name'].value = res.givenname;
  f['person_last_name'].value = res.sn;
  if (res.middlename) {
    f['person_middle_name'].value = res.middlename
  }
  if (res.generationqualifier) {
    f['person_suffix'].value = res.generationqualifier
  }
  if (res.displayname) {
    f['person_display_name'].value = res.displayname
  }
  if (res.postaladdress) {
    var pa = res.postaladdress.replace(/\$/g, "\n")
    pa = pa.replace(/\\N/g, "\n")
    f['person_postal_address'].value = pa
  }
  //if (res.postaladdress) {
  //  var aparts = res.postaladdress.split('$');
  //  f['person_office_address_line_one'].value = aparts[0];
  //  if (aparts[1]) { f['person_office_address_line_two'].value = aparts[1]; }
  //}

  if (res.mail) {
    f['person_email'].value = res.mail
  }
  if (res.telephonenumber) {
    f['person_phone'].value = res.telephonenumber
  }

  // Jump down to the form
  Element.scrollTo('personal_info')
}

$jq(function () {
  $jq('.ldap-result input').each(function(i, e) {
    $jq(e).click(function () {
      populate_person_form(i);
    })
  })
}
    )