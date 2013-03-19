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
  var query_url = 'https://www.googleapis.com/books/v1/volumes';
  $jq.ajax({url: query_url,
        data: {q: 'isbn:' + isbn},
        dataType: 'json'}
  ).done(function (data) {
        insert_google_link(data, span);
      })
}

function insert_google_link(data, span) {
  var volume_info = data['items'][0]['volumeInfo'];
  var link_url = volume_info['previewLink'];
  var image_url = volume_info['imageLinks']['smallThumbnail'];
  var image = document.createElement('img');
  $jq(image).attr('src', image_url);
  var link = document.createElement('a');
  $jq(link).attr('href', link_url);
  $jq(link).append(image);
  $jq(span).append(link);
}