// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function populate_person_form(ldap_result_index, form) {
  var f = $(form);
  var res = ldap_results[ldap_result_index];

  f['person_uid'].value = res.uid;
  f['person_first_name'].value = res.givenname;
  f['person_last_name'].value = res.sn;
  if (res.middlename) {
    f['person_middle_name'].value = res.middlename
  }
  if (res.generationqualifier) {
    f['person_suffix'].value = res.generationqualifier
  }
  if (res.displayname) {
    f['person_display_name'].value = res.displayname
  }
  if (res.postaladdress) {
    var pa = res.postaladdress.replace(/\$/g, "\n")
    pa = pa.replace(/\\N/g, "\n")
    f['person_postal_address'].value = pa
  }
  //if (res.postaladdress) {
  //  var aparts = res.postaladdress.split('$');
  //  f['person_office_address_line_one'].value = aparts[0];
  //  if (aparts[1]) { f['person_office_address_line_two'].value = aparts[1]; }
  //}

  if (res.mail) {
    f['person_email'].value = res.mail
  }
  if (res.telephonenumber) {
    f['person_phone'].value = res.telephonenumber
  }

  // Jump down to the form
  Element.scrollTo('personal_info')
}


/* select_all method
 *
 * Selects/Unselects all checkboxes in a given form on a page.
 * Requires passing in the checkbox field(s).
 *
 * HTML example:
 * <input type="checkbox" name="select_all" value="yes"
 *   onclick="selectAll(this, 'work_id[]');"/>
 *
 * HAML example:
 * = check_box_tag "select_all", "yes", false,
 *        :onclick=>"selectAll(this, 'work_id[]');"
 */
function select_all(globalField, checkboxName) {
  /*if global checkbox is selected, then select all checkboxes (and visa versa)*/
  if (globalField.checked == true) {
    selected = true;
  }
  else {
    selected = false;
  }

  var fieldsToSelect = document.getElementsByName(checkboxName);

  /*actually select/unselect all checkboxes */
  if (fieldsToSelect.length > 0) {
    for (var i = 0; i < fieldsToSelect.length; i++) {
      fieldsToSelect[i].checked = selected;
    }//end for
  }
  else {
    fieldsToSelect.checked = selected;
  }

}//end select_all


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


/**
 * submit_contributorships_form
 *
 * Calls either:
 *    /contributorships/verify_multiple,
 *    /contributorships/unverify_multiple, or
 *    /contributorships/deny_multiple
 * depending on the value of the 'action' parameter.
 *
 *  @form         = the form
 *  @checkboxName = name of the checkbox
 *  @action       = form action (e.g., '/contributorships/verify_multiple')
 *  @actionName   = name of the action (e.g., 'verify')
 *
 * HAML example:
 * = link_to_function "Verify everything selected",
 *        "submit_contributorship_form(document.works_form,
 *                            'contrib_id[]',
 *                            '#{verify_multiple_contributorships_path}',
 *                            'verify')"
 *
 * NOTE: Your form *MUST* also include the following hidden input,
 * or else RAILS will think this is a fraudelent request!
 *
 * = hidden_field_tag "authenticity_token", form_authenticity_token
 */
function submit_contributorships_form(form, checkboxName, action, actionName) {

  if (action == "null") {
    alert("No action selected");
    return false;
  }

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
    alert("Please select an item to " + actionName + ".");
    return false;
  }
  else if (count == 1) {
    msg = "Are you sure you want to " + actionName + " this item?"
  }
  else if (count > 1) {
    msg = "Are you sure you want to " + actionName + " the " + count + " selected items?"
  }

  /*Confirm before processing anything*/
  if (confirm(msg)) {
    /* Change form's method & action to process these items */
    form.method = 'POST';
    form.action = action;

    /* In Rails, the PUT method is specified via a hidden input named "_method" */
    var hiddenMethod = document.createElement('input');
    hiddenMethod.setAttribute('type', 'hidden');
    hiddenMethod.setAttribute('name', '_method');
    hiddenMethod.setAttribute('value', 'put');
    form.appendChild(hiddenMethod);

    /* Finally, submit our form to process the items! */
    form.submit();

  }
  return false;
}//end submit_contributorships_form


/**
 * submit_memberships_form
 *
 * First, verifies that a given checkbox field (specified
 * by 'checkboxName') has at least one item checked.  Then,
 * changes the current form on-the-fly into a
 * 'PUT' action, and submits it (to the speficied 'action')
 *
 * (Based on ideas from Railscast: Destroy without Javascript
 *  http://railscasts.com/episodes/77 )
 *
 *  @form         = the form
 *  @checkboxName = name of the checkbox
 *  @action       = form action (e.g., '/memberships/join_multiple')
 *
 * HAML example:
 * = link_to_function "Verify everything selected",
 *        "submit_memberships_form(document.memberships_form,
 *                                'group_id[]',
 *                                '#{join_multiple_memberships_path}')"
 *
 * NOTE: Your form *MUST* also include the following hidden input,
 * or else RAILS will think this is a fraudelent request!
 *
 * = hidden_field_tag "authenticity_token", form_authenticity_token
 */
function submit_memberships_form(form, checkboxName, action) {

  if (action == "null") {
    alert("No group selected");
    return false;
  }

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
    alert("Please select a group to join.");
    return false;
  }
  else if (count == 1) {
    msg = "Are you sure you want to join this group?"
  }
  else if (count > 1) {
    msg = "Are you sure you want to join these " + count + " groups?"
  }

  /*Confirm before processing anything*/
  if (confirm(msg)) {
    /* Change form's method & action to process these items */
    form.method = 'POST';
    form.action = action;

    /* In Rails, the PUT method is specified via a hidden input named "_method" */
    var hiddenMethod = document.createElement('input');
    hiddenMethod.setAttribute('type', 'hidden');
    hiddenMethod.setAttribute('name', '_method');
    hiddenMethod.setAttribute('value', 'put');
    form.appendChild(hiddenMethod);

    /* Finally, submit our form to process the items! */
    form.submit();

  }
  return false;
}// end submit_memberships_form

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
  var nameListID = "";

  //Check if we are working with authors or editors listing
  if (element.id == "author_string") {
    nameListID = "author_name_strings_list";
  }
  else if (element.id == "editor_string") {
    nameListID = "editor_name_strings_list";
  }

  return nameListID;
}

function decode_js_data_div(div_id) {
  if ($(div_id))
    return $(div_id).innerHTML.unescapeHTML().evalJSON(true);
  else
    return null;
}