$jq(function () {
      $jq('#global-checkbox').change(function () {
        jq_select_all(this, '#work-list input');
      });
      $jq('#works_form').submit(function () {
        return confirm_delete_for_items_selected_by('#work-list input:checked');
      })
    }
);