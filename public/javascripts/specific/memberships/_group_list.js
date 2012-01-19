$jq(
    $jq('.toggle-switch').click(function () {
      toggle_folder(this)
    }),
    $jq('.group-checkbox').change(function () {
      if (this.checked == true) {
        check_parent(this)
      }
    })
);

function toggle_folder(e) {
  $jq('#children_of_' + e.readAttribute('data-item-id')).toggle();
  if (e.innerHTML == "+") {
    $jq(e).html('&ndash; ')
  } else {
    $jq(e).html('+')
  }
}

function check_parent(e) {
  pid = e.readAttribute('data-parent-id');
  if (pid != null) {
    node = $jq('#group_id-' + pid);
    if (node == null) return;
    pnode = node.children()[1];
    if (!pnode.disabled) {
      pnode.checked = true;
    }
  }
}