$jq(function () {
      $jq('#global-checkbox').change(function () {
        jq_select_all(this, '#contributorships input');
      });
      $jq('#contributorships_form').submit(function () {
        //check validity of submission
        //null action - prevent submission
        var action = $jq('#action-select option:selected').attr('value');
        if (action == "null") {
          alert($jq.t('specific.contributorships.index.no_action'));
          return false;
        }
        var selected = $jq('#contributorships input:checked');
        var count = selected.length;
        if (count == 0) {
          alert($jq.t('specific.contributorships.index.select_' + action));
          return false;
        }
        var msg = $jq.t('specific.contributorships.index.confirm_' + action, {count:count});
        return confirm(msg);
      })
    }
);
