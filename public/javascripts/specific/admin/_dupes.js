$jq(function () {
      $jq('#global-checkbox').change(function () {
        jq_select_all(this, '#work-list input');
      });
      $jq('#dupes_form').submit(function () {
        return confirm_delete_for_items_selected_by('#dupes_form .select_multiple input:checked');
      })
    }
);