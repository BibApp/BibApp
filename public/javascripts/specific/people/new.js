function populate_person_form(ldap_result_index) {
  var ldap_results = decode_js_data_div('ldap_results');
  var res = ldap_results[ldap_result_index];

  $jq('#person_uid').val(res.uid);
  $jq('#person_first_name').val(res.givenname);
  $jq('#person_last_name').val(res.sn);
  if (res.middlename) {
    $jq('#person_middle_name').val(res.middlename)
  }
  if (res.generationqualifier) {
    $jq('#person_suffix').val(res.generationqualifier)
  }
  if (res.displayname) {
    $jq('#person_display_name').val(res.displayname)
  }
  if (res.postaladdress) {
    var pa = res.postaladdress.replace(/\$/g, "\n");
    pa = pa.replace(/\\N/g, "\n");
    $jq('#person_postal_address').val(pa)
  }
  if (res.mail) {
    $jq('#person_email').val(res.mail)
  }
  if (res.telephone) {
    $jq('#person_phone').val(res.telephone)
  }

  // Jump down to the form
  $jq('html').scrollTop($jq('#' + 'personal_info').position().top)
}

$jq(function () {
      $jq('.ldap-result input').each(function (i, e) {
        $jq(e).click(function () {
          populate_person_form(i);
        })
      })
    }
);