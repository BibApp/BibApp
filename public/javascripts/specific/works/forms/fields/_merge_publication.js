function populatePubFields(textbox, listitem) {
  var my_array = listitem.id.split('~~');
  var publisher = my_array[0];
  var issn_isbn = my_array[1];
  document.getElementById('publisher_name').value = publisher;
  document.getElementById('issn_isbn').value = issn_isbn;
}
