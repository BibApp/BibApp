function requested_locale() {
  return $jq("meta[name=requested-locale]").attr("content");
}

function datatables_language_url() {
  return "/datatables/" + requested_locale() + ".txt"
}

//initialize jsperanto to do translations for javascript code
//note that it may take a moment for translations to become available as the dictionary is loaded
//via AJAX, but I don't see any good way around that. In practice I don't expect it to be a problem.
$jq(function () {
      var opts = {
            fallbackLang: "en",
            dicoPath: "/javascripts/translations",
            setDollarT: false,
            lang: requested_locale()
          };
      $jq.jsperanto.init(function(t) {
          }, opts
      )
      $jq.t = $jq.jsperanto.t;
    }
)
