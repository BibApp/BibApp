function arm_checkboxes() {
  $jq('.name_string_checkbox').each(function() {
    //if selected, then on deselection delete namestring via ajax and remove checkbox from view. Regenerate list
    //of current namestrings, display, and rearm checkboxes

    //if not selected, then on selection add namestring via ajax, remove checkbox from view, regenerate list of
    //current namestrings, display, and rearm checkboxes
    $jq(this).change(function () {
      var name = $jq(this).attr('name');
      var update_url = $jq(this).siblings('.update_url').val();
      $jq(this).parent('li').remove();
      $jq.ajax({
        url: update_url,
        type: 'POST',
        data: {person_id: $jq('#person_id').val(), name_string_id: name},
        success: function(data, status, xhr) {
          $jq('#current').replaceWith(data);
          arm_checkboxes();
        }
      })
    });
  })
}

$jq(function () {
  //handle adding a new name string via remote form
  $jq('#new_name_string_form').bind('ajax:success', function (event, data, status, xhr) {
    $jq('#current').replaceWith(data);
    $jq('#name_string_name').val('');
    arm_checkboxes();
  });
  //handle name string search
  $jq('#name_string_search_form').bind('ajax:success', function (event, data, status, xhr) {
    $jq('#inactive').html(data);
    $jq('#name_string_search_form input[name="q"]').val('');
    arm_checkboxes();
  });
  arm_checkboxes();
});