// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

//Alias jQuery
//TODO after all the prototype is out we can undo this
var $jq = jQuery;

/*
  set the checked attribute of anything selected by the dependentCheckboxSelector
  to be the same as that of the element globalCheckbox
  Intended to be used to set up callbacks on globalCheckbox
 */
function jq_select_all(globalCheckbox, dependentCheckboxSelector) {
  $jq(dependentCheckboxSelector).each(function(i, e) {
    $jq(e).attr('checked', $jq(globalCheckbox).attr('checked'))
  })
}

/* this is for attaching to a form before submission. It figures out how many of the
  checkboxes selected by the selector are checked and displays a
  confirmation message and affects form submission depending on that.
 */
function confirm_delete_for_items_selected_by(checkbox_selector) {
  var selected = $jq(checkbox_selector);
  var count = selected.length;
  if (count == 0) {
    alert($jq.t("application.select_item"));
    return false;
  }
  var msg = $jq.t("application.confirm_delete", {count:count});
  return confirm(msg);
}

function decode_js_data_div(div_id) {
  var div = $jq('#' + div_id);
  if(div)
    return $jq.parseJSON(div.text());
  else
    return null;
}

//Do an ajax get to the url and append the results to the element(s) selected by the selector
function ajax_append(url, selector) {
  $jq.ajax({url: url,
    success: function(data) {
      $jq(selector).append(data);
    }
  })
}
