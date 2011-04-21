function toggle_folder(fid) {
  $('children_of_' + fid).toggle();
  if ($('toggle_switch_' + fid).innerHTML == '+') {
    $('toggle_switch_' + fid).innerHTML = '&ndash; ';
  } else {
    $('toggle_switch_' + fid).innerHTML = '+';
  }
}

function check_parent(pid) {
  if (pid != null) {
    if ($('group_id-' + pid) == null) return;
    pnode = $('group_id-' + pid).childElements()[1];
    if (!pnode.disabled) {
      pnode.checked = true;
      pnode.onclick();
    }
  }
}

