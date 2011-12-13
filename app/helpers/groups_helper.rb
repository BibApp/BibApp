module GroupsHelper
  def body_header(group)
    (group.name + link_to(fugue_icon_tag('feed'), group_path(@group, :format => "rss"))).html_safe
  end

  def parent_link(group)
    group.parent ? link_to(group.parent.name, group.parent) : ''
  end

end
