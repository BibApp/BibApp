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
  //lookup stuff
  var urls = lookup_google_links(isbn)
  var image = document.createElement('img');
  $jq(image).attr('src', urls['link_url']);
  var link = document.createElement('a');
  $jq(link).attr('href', urls['image_url']);
  $jq(link).append(image);
  $jq(span).append(link);
}

function lookup_google_links(isbn) {
  var hash = {
    link_url: 'http://books.google.com/books?id=0JA_uAAACAAJ&dq=isbn:9780470189481&hl=&cd=1&source=gbs_api',
    image_url: 'http://bks3.books.google.com/books?id=0JA_uAAACAAJ&printsec=frontcover&img=1&zoom=5&source=gbs_api'
  };
  return hash;
}