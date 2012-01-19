function post_list() {
  var ids = $jq('#current li').map(function() {return this.id}).get();
  var url = $jq('#sort_url').attr('value');
  var person_id = $jq('#person_id').attr('value');
  $jq.ajax({
    url: url,
    type: "POST",
    data: {person_id: person_id, ids: ids}
  })
}

$jq(function () {
  $jq('#current').sortable({
    placeholder:"ui-state-highlight",
    update:function () {
      post_list()
    }
  });
  $jq('.membership-group-form form').bind('ajax:success', function (event, data, status, xhr) {
    $jq(this).effect('highlight', null, 2000);
  })
});


