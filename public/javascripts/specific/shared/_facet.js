function toggle_facets(element) {
  var facet = $jq(element).parents('.facet');
  facet.children('.top_facets').toggle();
  facet.children('.all_facets').toggle();
  facet.children('.more_filters').toggle();
  facet.children('.fewer_filters').toggle();
}
