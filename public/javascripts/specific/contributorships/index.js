$jq(function () {
  $jq('#global-checkbox').change(function () {
    jq_select_all(this, '#contributorships input');
  })
}
    )