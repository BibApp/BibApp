function requested_locale() {
  return $jq("meta[name=requested-locale]").attr("content");
}

function datatables_language_url() {
  return "/datatables/" + requested_locale() + ".txt"
}