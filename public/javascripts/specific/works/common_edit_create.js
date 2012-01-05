function remove_enclosing_list_item(element) {
  $jq(this).closest('li').remove();
}