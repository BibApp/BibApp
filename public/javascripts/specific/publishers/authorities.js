function highlight_candidates() {
  $jq('tr.authority_option').each(function(i, e) {
    $jq('#publisher_' + $jq(this).attr('id')).addClass('selected')
  })
}

$jq(function () {
  highlight_candidates();
});

// Make table into javascript widget
$jq(document).ready(function() {
	$jq('#publishers').dataTable( {
    "aaSorting": [[1, "asc"]],
    "aLengthMenu": [10, 25, 50, 100],
    "iDisplayLength": 25,
    "sPaginationType": "full_numbers",
    "bStateSave": true,
    "iCookieDuration": 600,
    "bSort": true,
    "oLanguage": {
      "sUrl": datatables_language_url()
    },
    "aoColumns": [null, {"sType": 'title-string'}, null]
  });
} );