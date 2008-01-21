class Person < ActiveRecord::Base
  has_many :authors, :through => :pen_names
  has_many :pen_names
  has_many :groups, :through => :memberships
  has_many :memberships
  
  def citations
    citations = Citation.find(
      :all,
      :joins =>
        "join authorships on citations.id = authorships.citation_id
        join authors on authorships.author_id = authors.id
        join pen_names on authors.id = pen_names.author_id
        join people on pen_names.person_id = people.id",
      :conditions => ["people.id = ? and citations.citation_state_id = ?", self.id, 3],
      :order => "citations.year DESC, citations.title_primary"
    )
  end

  def first_last
    "#{first_name} #{last_name}"
  end
  
  def to_param
    param_name = first_last.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end
  

  def groups_not
    all_groups = Group.find(:all, :order => "name")
    # TODO: do this right. The vector subtraction is dumb.
    return all_groups - groups
  end
  
  def authors_not
    all_authors = Author.find(:all, :order => "name")
    # TODO: do this right. The vector subtraction is dumb.
    return all_authors - authors
  end
end