$jq(function() {
  $jq('#memberships_form').submit(function () {
    var selected = $jq('.group-checkbox:checked');
    var count = selected.length;
    if (count == 0) {
      alert ('Please select a group to join.');
      return false;
    }
    var msg = "Are you sure you want to join "
    if (count == 1) {
      msg = msg + " this group?"
    } else {
      msg = msg + ' these ' + count + " groups?"
    }
    return confirm(msg);
  })
})