function highlight_candidates() {
  $jq('tr.authority_option').each(function(i, e) {
    $jq('#publication_' + this.id).removeClass("even odd").addClass('selected');
  })
}

$jq(function () {
  highlight_candidates();
});

// Make table into javascript widget
$jq(document).ready(function() {
	$jq('#publications').dataTable( {
    "aaSorting": [[2, "asc"]],
    "aLengthMenu": [10, 25, 50, 100],
    "iDisplayLength": 25,
    "sPaginationType": "full_numbers",
    "bStateSave": true,
    "iCookieDuration": 600,
    "bSort": true,
    "oLanguage": {
      "sUrl": datatables_language_url()
    },
    "aoColumns": [null, null, {"sType": 'title-string'}, {"sType": 'title-string'}, null]
  });
} );