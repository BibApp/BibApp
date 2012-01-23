function remove_enclosing_list_item(element) {
  $jq(element).closest('li').remove();
}

var author_list_item_template = null;
function store_author_list_item_template() {
  author_list_item_template = $jq('#author_name_strings_list li').first().clone();
  author_list_item_template.children('.text').attr('value', '');
}

var contributor_list_item_template = null;
function store_contributor_list_item_template() {
  contributor_list_item_template = $jq('#contributor_name_strings_list li').first().clone();
  contributor_list_item_template.children('.text').attr('value', '');
}

function add_author_list_item() {
  var new_item = author_list_item_template.clone();
  new_item.attr('id', 'author_' + $jq('#author_name_strings_list li').length);
  $jq('#author_name_strings_list').append(new_item);
}

function add_contributor_list_item() {
  var new_item = contributor_list_item_template.clone();
  new_item.attr('id', 'contributor_' + $jq('#contributor_name_strings_list li').length);
  $jq('#contributor_name_strings_list').append(new_item);
}

$jq(function () {
  store_author_list_item_template();
  store_contributor_list_item_template();
  $jq('#author_name_strings_list').sortable({placeholder:"ui-state-highlight", items:'li'});
  $jq('#contributor_name_strings_list').sortable();
});