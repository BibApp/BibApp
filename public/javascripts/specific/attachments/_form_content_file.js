function toggle_license() {
  $jq('#license').toggle();
}

function add_upload_box(url) {
  ajax_append(url, '#upload_files');
}

$jq(function () {
  $jq('form').submit(function () {
        if (!$jq('#license_agree').get(0).checked) {
          $jq('#license_warning').toggle();
          return false;
        } else {
          return true;
        }
      }
  );
  $jq('#license_agree').change(function () {
    if (this.checked) {
      $jq('#license_warning').hide();
    }
  })
});
