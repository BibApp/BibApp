var year_index = 0;
var year_tags = decode_js_data_div('year-tags')
var charts = decode_js_data_div('chart-urls')
var work_counts = decode_js_data_div('work-counts')

function show_list(year) {
  var items = $('timeline-tagcloud').getElementsByTagName('ul');
  for (var i = 0; i < items.length; i++) {
    var l = items[i];
    if (l.id == "list-" + year) {
      l.style.display = "block";
    }
    else {
      l.style.display = "none";
    }
  }
}

function set_year(ydata, num) {
  if (ydata) {
    var header = document.getElementById("curyear");
    header.innerHTML = ydata;
    var chart = document.getElementById("chart-img");
    if (work_counts[num] == 0) {
      chart.innerHTML = "<p>No data</p>"
    } else {
      chart.innerHTML = "<img src='" + charts[num] + "' title='" + $jq.jsperanto.t("specific.keywords.timeline.title") + "'/>";
    }
    show_list(ydata);
  }
}

var year_range = new Array(year_tags.length);
for (var i = 0; i < year_range.length; i++) {
  year_range[i] = i;
}

var slider = new Control.Slider('handle1', 'track1', {
  axis:       'horizontal',
  range: $R(0, year_range.length - 1),
  values: year_range
});

set_year(year_tags[0], 0);
slider.options.onSlide = function(v) {
  set_year(year_tags[v], v);
};
slider.setEnabled();