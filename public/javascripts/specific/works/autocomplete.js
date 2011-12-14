$jq(function() {
  $jq.each({'#publication_name': '/publications/autocomplete.json',
          '#publisher_name': '/publishers/autocomplete.json'},
      function(id, url) {
        $jq(id).autocomplete({source: url})
      })
})