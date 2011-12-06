$jq(document).ready(function() {
  $jq('#people').dataTable({
    "aaSorting": [
      [1, "desc"]
    ],
    "aLengthMenu": [10, 25, 50, 100],
    "iDisplayLength": 25,
    "sPaginationType": "full_numbers",
    "oLanguage": {
      "sUrl": datatables_language_url()
    }
  });
});