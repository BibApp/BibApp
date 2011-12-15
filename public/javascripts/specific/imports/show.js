// Matched PenNames

function matchedPenNames() {

  // 1) Show all Imported Work NamesStrings
  var lines = new Array();
  lines = $('import_names').childElements();
  lines.each(function(li) {
    li.show();
  });

  // 2) Find all claimed PenNames
  var pen_names = $$('td.pen_name');

  // 3) For each claimed PenName, hide Imported Work NameStrings with matching Work associations
  pen_names.each(function(pn) {
    var works = new Array();
    var name_string = new String();
    name_string = "ns-" + pn.id;
    import_name_string = $(name_string);
    if (import_name_string != null) {
      works = $w(import_name_string.className);
      works.each(function(work) {
        var match = new String();
        match = "li." + work
        $$(match).each(function(w) {
          w.hide();
        });
      });

      // 4) Set PenName Imported Work Count and Total

      var pen_name_work_count = new String();
      pen_name_work_count = "pn-" + pn.id + "-count";

      var name_string_work_count = new String();
      name_string_work_count = "ns-" + pn.id + "-count";

      if ($(name_string_work_count).innerHTML != null) {
        $(pen_name_work_count).innerHTML = $(name_string_work_count).innerHTML
      }
    }

  });

  // 5) Set PenName match total
  total = 0;
  imported = parseInt($('works_imported_total').innerHTML);

  $$('td.pen_name_count').each(function(c) {
    total = total + parseInt(c.innerHTML);
  });

  $('pen_names_count_total').innerHTML = total;
  $('matched_total').innerHTML = $jq.t("specific.imports.show.matched_total", {count: total});

  remaining = imported - total;
  if (remaining > 0) {
    $('remaining_total').innerHTML = $jq.t("specific.imports.show.remaining_total", {count: remaining});
    $('remaining_total').addClassName("error")
  }
  else {
    $('remaining_total').innerHTML = $jq.t("specific.imports.show.remaining_total_zero");
    $('remaining_total').removeClassName("error")
  }

}

// On Document load
document.observe("dom:loaded", function() {
 // matchedPenNames();
});