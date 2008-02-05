class GroupsController < ApplicationController
  make_resourceful do 
    build :all

    before :index do
      @groups = Group.paginate(
        :all,
        :order => "name",
        :page => params[:page] || 1,
        :per_page => 10
      )
    end
    
    before :show do 
      # @TODO map group.citations should be railsy
      @citations = Citation.paginate(
        :all,
        :joins => "
          join citation_author_strings on citations.id = citation_author_strings.citation_id
          join author_strings on citation_author_strings.author_string_id = author_strings.id
          join pen_names on author_strings.id = pen_names.author_string_id
          join people on pen_names.person_id = people.id
          join memberships on people.id = memberships.person_id
          join groups on memberships.group_id = groups.id
          ",
        :conditions => ["groups.id = ? and citations.citation_state_id = ?", params[:id], 3],
        :order => "citations.year DESC, citations.title_primary",
        :page => params[:page] || 1,
        :per_page => 10
      )
    end
  end
end
