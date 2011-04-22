// Highlight selected authority candidates
function highlight_candidates() {

  // Find all authority candidates
  auth_opts = $$('tr.authority_option');
  auth_opts.each(function(tr) {
    select = new String();
    select = "publisher_" + tr.id;

    // If candidate row is listed on current page, "highlight" the row
    if ($(select)) {
      $(select).removeClassName("even");
      $(select).removeClassName("odd");
      $(select).addClassName("selected");
    }
  })
}

// On Document load
document.observe("dom:loaded", function() {
  highlight_candidates();
});