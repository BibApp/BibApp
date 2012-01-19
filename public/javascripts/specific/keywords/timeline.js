var year_tags = decode_js_data_div('year-tags');
var charts = decode_js_data_div('chart-urls');
var work_counts = decode_js_data_div('work-counts');
var slider_div = $jq('#track1');

function slider_stop() {
  var index = slider_div.slider('value');
  show_year(index);
  show_chart(index);
  show_list(index);
}

function show_year(index) {
  $jq('#curyear').text(year_tags[slider_div.slider('value')]);
}

function show_chart(index) {
  var html;
  if (work_counts[index] == 0) {
    html = "<p>No data</p>";
  } else {
    html = "<img src='" + charts[index] + "' title='" + $jq.jsperanto.t("specific.keywords.timeline.title") + "'/>";
  }
  $jq('#chart-img').html(html);
}

function show_list(index) {
  $jq('#timeline-tagcloud ul').each(function(i, e) {
    if(i == index) {
      $jq(this).css('display', 'block');
    } else {
      $jq(this).css('display', 'none');
    }
  });
}

$jq(function () {
  slider_div.slider({
    min:0,
    max:year_tags.length - 1,
    value:0,
    stop:function () {
      slider_stop()
    }
  });
  slider_stop();
});

