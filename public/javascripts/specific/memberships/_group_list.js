$jq(
    $jq('.toggle-switch').click(function () {
      toggle_folder(this)
    }),
    $jq('.group-checkbox').change(function () {
      if (this.checked) {
        check_parent(this)
      }
    })
);

function toggle_folder(e) {
  $jq('#children_of_' + $(e).attr('data-item-id')).toggle();
  if (e.innerHTML == "+") {
    $jq(e).html('&ndash; ')
  } else {
    $jq(e).html('+')
  }
}

function check_parent(e) {
  var pid = $(e).attr('data-parent-id');
  if (pid != null) {
    var node = $jq('#group_id-' + pid);
    if (node == null) return;
    var pnode = node.children()[1];
    if (!pnode.disabled) {
      pnode.checked = true;
    }
  }
}