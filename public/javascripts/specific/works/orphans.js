{
  function set_orphan_state(val) {
    $jq('.orphan_checkbox').each(
        function(i, e) {
          e.checked = val
        })
  }

  function check_all_orphans() {
    set_orphan_state(1);
  }

  function uncheck_all_orphans() {
    set_orphan_state(0);
  }

  $jq( function () {
    $jq('#check-all').click(check_all_orphans);
    $jq('#uncheck-all').click(uncheck_all_orphans)
  })

}