class Group < ActiveRecord::Base
  has_many :people,
    :through => :memberships
  has_many :memberships

  def citations
    citations = Citation.find(
      :all,
      :joins => "
        join citation_author_strings on citations.id = citation_author_strings.citation_id
        join author_strings on citation_author_strings.author_string_id = author_strings.id
        join pen_names on author_strings.id = pen_names.author_string_id
        join people on pen_names.person_id = people.id
        join memberships on people.id = memberships.person_id
        join groups on memberships.group_id = groups.id
        ",
      :conditions => ["groups.id = ? and citations.citation_state_id = ?", self.id, 3],
      :order => "citations.year DESC, citations.title_primary"
    )
  end

  def to_param
    param_name = name.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end  
end