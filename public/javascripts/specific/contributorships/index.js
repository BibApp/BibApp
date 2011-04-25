$jq(function () {
  $jq('#global-checkbox').change(function () {
    jq_select_all(this, '#contributorships input');
  });
  $jq('#contributorships_form').submit(function () {
    //check validity of submission
    //null action - prevent submission
    var action = $jq('#action-select option:selected').attr('value');
    if (action == "null") {
      alert('No action selected');
      return false;
    }
    var selected = $jq('#contributorships input:checked')
    var count = selected.length;
    if (count == 0) {
      alert ('Please select an item to ' + action + '.');
      return false;
    }
    var msg = "Are you sure you want to " + action
    if (count == 1) {
      msg =  msg + " this item?"
    } else {
      msg = msg + " the " + count + " selected items?"
    }
    return confirm(msg);
  })
}
    )
