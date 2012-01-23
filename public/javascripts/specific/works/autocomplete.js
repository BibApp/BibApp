$jq(function () {
  $jq.each({'#publication_name':'/publications/autocomplete.json',
        '#publisher_name':'/publishers/autocomplete.json',
        '#author_name_strings_list input.text':'/name_strings/autocomplete.json',
        '#contributor_name_strings_list input.text':'/name_strings/autocomplete.json'},
      function (selector, url) {
        $jq(selector).autocomplete({source:url})
      })
});