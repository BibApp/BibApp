module MembershipsHelper
  def ajax_checkbox_toggle(group, person, selected)
    if selected
      js = remote_function(
        :url => {
          :action => :destroy,
          :person_id => person.id, 
          :group_id => group.id},
        :method => :delete
      )
    else
      js = remote_function(
        :url => {
          :action => :create,
          :person_id => person.id, 
          :group_id => group.id
          },
        :method => :post
      )
    end
    check_box_tag("group_#{group.id}_toggle", 1, selected, :onclick => js)
  end
end
