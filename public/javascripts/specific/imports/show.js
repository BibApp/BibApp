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

  //This is just a jquery way of getting the html for the full <a> element as a string. One thing jquery doesn't make easy.
  var link_string = $jq('#matched_total a').clone().wrap('<div>').parent().html();
  var text;
  if(total != 0) {
    text = $jq.t('specific.imports.show.matched_total', {count: total, imported_for: link_string});
  } else {
    text = $jq.t('specific.imports.show.matched_total_zero', {count: total, imported_for: link_string});
  }

  $jq('#matched_total').html(text);

  var remaining = imported - total;
  if (remaining > 0) {
    text = $jq.t("specific.imports.show.remaining_total", {count: remaining});
    $jq('#remaining_total').addClass('error').text(text);
  } else {
    $jq('#remaining_total').removeClass('error').text($jq.t("specific.imports.show.remaining_total_zero"))
  }
}

function set_namestring_callbacks() {
  var person_id = $jq('#person-id').text();
  var import_id = $jq('#import-id').text();
  var url = '/users/' + person_id + '/imports/' + import_id + '/';
  $jq('#current_pen_names input[type="checkbox"]').each(function() {
    $jq(this).change(function() {
      $jq.ajax({
        url: url + 'destroy_pen_name',
        data: {
          name_string_id: $jq(this).closest('td').attr('id'),
          person_id: person_id
        },
        type: 'POST',
        success: function(data, status, xhr) {
          rerender_namestring_lists(data)
        }
      })
    });
  });
  $jq('#imported_pen_names input[type="checkbox"]').each(function() {
    $jq(this).change(function() {
      $jq.ajax({
        url: url + 'create_pen_name',
        data: {
          person_id: person_id,
          name_string_id: $jq(this).closest('li').attr('id').split('-')[1]
        },
        type: 'POST',
        success: function(data, status, xhr) {
          rerender_namestring_lists(data)
        }
      })
    });
  });
}

function rerender_namestring_lists(data) {
  var json = $jq.parseJSON(data);
  $jq('#current_pen_names').replaceWith(json.current_pen_names);
  $jq('#imported_pen_names').replaceWith(json.imported_pen_names);
  set_namestring_callbacks();
  matchedPenNames();
}

$jq(function () {
  set_namestring_callbacks();
  $jq.jsperanto.init(function () {
    matchedPenNames();
  })
});
