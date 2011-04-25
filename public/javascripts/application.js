// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

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
    alert('Please select an item to delete.');
    return false;
  }
  var msg = "Are you sure you want to permanently delete ";
  if (count == 1) {
    msg = msg + "this item?";
  } else {
    msg = msg + "these " + count + " items?";
  }
  return confirm(msg);
}

/* Used in admin/_dupes, import/works, works/review_batch */
/* submit_delete_form method
 *
 * First, verifies that a given checkbox field (specified
 * by 'checkboxName') has at least one item checked.  Then,
 * changes the current form on-the-fly into a
 * 'destroy' action, and submits it (to the speficied 'action')
 *
 * (Based on ideas from Railscast: Destroy without Javascript
 *  http://railscasts.com/episodes/77 )
 *
 * HAML example:
 * = link_to_function "Delete everything selected",
 *        "submit_delete_form(document.works_form,
 *                            'work_id[]',
 *                            '#{destroy_multiple_works_path}')"
 *
 * NOTE: Your form *MUST* also include the following hidden input,
 * or else RAILS will think this is a fraudelent request!
 *
 * = hidden_field_tag "authenticity_token", form_authenticity_token
 */


function submit_delete_form(form, checkboxName, action) {
  var msg = "";
  /*Count the number of selected fields for our confirmation message */
  var count = 0;
  var fields = document.getElementsByName(checkboxName);

  if (fields.length > 0) {
    for (var i = 0; i < fields.length; i++) {
      if (fields[i].checked == true) {
        count++;
      }
    }//end for
  }
  else {
    if (fields.checked == true) {
      count++;
    }
  }


  /* Only continue if we have an item seleted */
  if (count == 0) {
    alert("Please select an item to delete.");
    return false;
  }
  else if (count == 1) {
    msg = "Are you sure you want to permanently delete this item?"
  }
  else if (count > 1) {
    msg = "Are you sure you want to permanently delete the " + count + " selected items?"
  }

  /*Confirm before deleting anything*/
  if (confirm(msg)) {
    /* Change form's method & action to delete these items */
    form.method = 'POST';
    form.action = action;

    /* In Rails, the DELETE method is specified via a hidden input named "_method" */
    var hiddenMethod = document.createElement('input');
    hiddenMethod.setAttribute('type', 'hidden');
    hiddenMethod.setAttribute('name', '_method');
    hiddenMethod.setAttribute('value', 'delete');
    form.appendChild(hiddenMethod);

    /* Finally, submit our form to delete the items! */
    form.submit();
  }
  return false;
}//end submit_delete_form

/*=============================
 * Create/Edit Work Form
 *=============================*/

/* Custom Scriptaculuous autocomplete onShow script
 *
 * This is called "on_show" for an autocomplete text field. It
 * essentially displays the autocomplete values, while also disabling
 * the reorder capabilities from the existing list of authors.
 *
 * Call similar to:
 * text_field_with_auto_complete :author, :string, {},
 *    {:on_show =>
 *     "function(element, update) {show_autocomplete_names(element, update);}" }
 *
 * Note: The Scriptaculous 'sortable_element' and 'text_field_with_autocomplete'
 * have conflicting Javascript which essentially causes the two fields to
 * overlap and look ugly.  This method ensures we are *completely* disabling
 * the 'sortable_element' field whenever autocomplete is occurring.
 *
 * This method works for either a list of AUTHORS or a list of EDITORS.
 *
 * Customized from Autocompleter.Base code in /javascripts/control.js
 */
function show_autocomplete_names(element, update) {
  if (!update.style.position || update.style.position == 'absolute') {
    update.style.position = 'absolute';
    Position.clone(element, update, {
      setHeight: false,
      offsetTop: element.offsetHeight
    });
  }
  Effect.Appear(update, {duration:0.15});

  /* Start custom BibApp code */
  nameListID = get_name_list_id(element);

  if (nameListID.length > 0) {
    //Get our list our names
    nameList = Element.childElements(nameListID);

    //Temporarily remove ability to sort the list
    Sortable.destroy(nameListID);

    //Temporarily remove 'movable' class from all list items
    for (var i = 0; i < nameList.length; i++) {
      nameList[i].removeClassName('movable');
    }
  }//end if nameListID
}


/* Custom Scriptaculuous autocomplete onShow script
 *
 * This is called "on_hide" for an autocomplete text field. It
 * essentially hides the autocomplete values, while also re-enabling
 * the reorder capabilities for the existing list of authors.
 *
 * Call similar to:
 * text_field_with_auto_complete :author, :string, {},
 *    {:on_hide =>
 *     "function(element, update) {hide_autocomplete_names(element, update);}" }
 *
 * Note: The Scriptaculous 'sortable_element' and 'text_field_with_autocomplete'
 * have conflicting Javascript which essentially causes the two fields to
 * overlap and look ugly.  This method ensures we are only re-enabling the
 * 'sortable_element' field once the autocomplete functionality has finished.
 *
 * This method works for either a list of AUTHORS or a list of EDITORS.
 *
 * Customized from Autocompleter.Base code in /javascripts/control.js
 */
function hide_autocomplete_names(element, update) {
  new Effect.Fade(update, {duration:0.15})

  /* Start custom BibApp code */
  nameListID = get_name_list_id(element);

  if (nameListID.length > 0) {
    //Get our list our names
    nameList = Element.childElements(nameListID);

    //re-Add 'movable' class to all list items
    for (var i = 0; i < nameList.length; i++) {
      nameList[i].addClassName('movable');
    }
    //Make name list sortable again
    Sortable.create(nameListID);
  }//end if nameListID
}

/*
 * This method is used by show_autocomplete_names()
 * and hide_autocomplete_names() to get the ID of the
 * list of names associated with a given text element.
 */
function get_name_list_id(element) {
  return element.id.replace('string', 'name_strings_list')
}

function decode_js_data_div(div_id) {
  div = $jq('#' + div_id)
  if(div)
    return $jq.parseJSON(div.text());
  else
    return null;
}
