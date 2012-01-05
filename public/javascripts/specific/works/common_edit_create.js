function remove_enclosing_list_item(element) {
  $jq(element).closest('li').remove();
}