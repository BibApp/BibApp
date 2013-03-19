

$jq(function () {
      get_google_links();
    }
)

function get_google_links() {
  $jq('span.google-book').each(function () {
    get_google_link(this)
  })

}

function get_google_link(span) {
  var isbn = $jq(span).attr('title');
  var query_url = '/works/google_book_data';
  $jq.ajax({url: query_url,
        data: {isbn: isbn},
        dataType: 'json'}
  ).done(function (data) {
        insert_google_link(data, span);
      })
}

function insert_google_link(data, span) {
  var link_url = data['link_url'];
  var image_url = data['image_url']
  var image = document.createElement('img');
  $jq(image).attr('src', image_url);
  var link = document.createElement('a');
  $jq(link).attr('href', link_url);
  $jq(link).append(image);
  $jq(span).append(link);
}