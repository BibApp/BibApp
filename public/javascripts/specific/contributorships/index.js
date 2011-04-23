$jq(function () {
  $jq('#global-checkbox').change(function () {
    jq_select_all(this, '#contributorships input');
  });
  $jq('#contributorship-submit').click(function () {
    //check validity of submission
  })
}
    )

/*
, "sel=document.contributorships_form.do_to_all;submit_contributorships_form(document.contributorships_form, 'contrib_id[]', sel.options[sel.options.selectedIndex].value, sel.options[sel.options.selectedIndex].id)"

    */