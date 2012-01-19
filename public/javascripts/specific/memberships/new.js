$jq(function () {
  $jq('#memberships_form').submit(function () {
    var selected = $jq('.group-checkbox:checked');
    var count = selected.length;
    if (count == 0) {
      alert($jq.t("specific.memberships.new.select_group"));
      return false;
    }
    var msg = $jq.t("specific.memberships.new.confirm", {count:count});
    return confirm(msg);
  })
});