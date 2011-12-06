// Highlight selected authority candidates
function highlight_candidates() {

  // Find all authority candidates
  auth_opts = $$('tr.authority_option');
  auth_opts.each(function(tr) {
    select = new String();
    select = "publisher_" + tr.id;

    // If candidate row is listed on current page, "highlight" the row
    if ($(select)) {
      $(select).removeClassName("even");
      $(select).removeClassName("odd");
      $(select).addClassName("selected");
    }
  })
}

// On Document load
document.observe("dom:loaded", function() {
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
    "bSort": false,
    "oLanguage": {
      "sUrl": datatables_language_url()
    }
  });
} );