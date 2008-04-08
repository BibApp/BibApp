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
          join contributorships on citations.id = contributorships.citation_id
          join people on contributorships.person_id = people.id
          join memberships on people.id = memberships.person_id
          join groups on memberships.group_id = groups.id
          ",
        :conditions => ["groups.id = ? and contributorships.contributorship_state_id = ?", params[:id], 2],
        :order => "citations.year DESC, citations.title_primary",
        :page => params[:page] || 1,
        :per_page => 10
      )
    end
  end
end
