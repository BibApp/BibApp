module GroupsHelper
  def body_header(group)
    (group.name + link_to(image_tag("feed-icon-14x14.png"), group_path(@group, :format => "rss"))).html_safe
  end
end
