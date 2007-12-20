class GroupsController < ApplicationController
  make_resourceful do 
    build :all
    
    before :show do 
      @citations = Citation.paginate(
        :all,
        :joins => ["
          join authorships on citations.id = authorships.citation_id
          join authors on authorships.author_id = authors.id
          join pen_names on authors.id = pen_names.author_id
          join people on pen_names.person_id = people.id
          join memberships on people.id = memberships.person_id
          join groups on memberships.group_id = groups.id
          "],
        :conditions => ["groups.id = ? and citations.citation_state_id = ?", params[:id], 3],
        :order => "citations.year DESC, citations.title_primary",
        :page => params[:page] || 1,
        :per_page => 10
      )
    end
  end
end
