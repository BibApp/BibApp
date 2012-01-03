// Matched PenNames

function matchedPenNames() {
  showLines();
  displayPenNames();
  setMatchTotals();
}

function showLines() {
  $jq("#import_names li").each(function () {
    $jq(this).show();
  })
}

function displayPenNames() {
  $jq('td.pen_name').each(function() {
    var id = $jq(this).attr('id');
    var import_name_string = $jq('#ns-' + id);
    if (import_name_string.length != 0) {
      var works = $jq(import_name_string.attr('class').split(' '));
      works.each(function() {
        $jq('li.' + this).hide();
      });
    }
    var pen_name_work_count = $jq('#pn-' + id + '-count');
    var name_string_work_count = $jq('#ns-' + id + '-count');
    if (name_string_work_count.html() != null) {
      pen_name_work_count.html(name_string_work_count.html());
    }
  });
}

function setMatchTotals() {
  var imported = parseInt($jq('#works_imported_total').text());

  var total = 0;
  $jq('td.pen_name_count').each(function () {
    total = total + parseInt($jq(this).text());
  });

  $jq('#pen_names_count_total').html(total);

  var remaining = imported - total;
  if (remaining > 0) {
    $jq('#remaining_total').addClass('error').html(remaining_message(remaining));
  } else {
    $jq('#remaining_total').removeClass('error').html($jq.t("specific.imports.show.remaining_total_zero"))
  }
}

function remaining_message(count) {
  $jq.t("specific.imports.show.remaining_total", {count: count});
}

$jq(function () {
  matchedPenNames();
});
