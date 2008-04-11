class ContributorshipsController < ApplicationController
  make_resourceful do
    build :index
    
    before :index do
      if params[:person_id]
        @person = Person.find(params[:person_id])
        @contributorships = @person.contributorships.to_show.paginate(
          :page => params[:page] || 1,
          :per_page => 10
        )
      end
    end
  end
  
  def verify
    # @TODO: Auth check here
    @contributorship = Contributorship.find(params[:id])
    person = @contributorship.person
    
    @contributorship.update_attributes(:contributorship_state_id => 2)
    person.update_scoring_hash
    
    @contributorship.person.contributorships.calculated.each do |c|
      c.calculate_score
    end
    
    @contributorships = person.contributorships.to_show
    
    respond_to do |format|
      format.js { render :action => :verify_contributorship }
    end
  end
  
  def deny
    # @TODO: Auth check here
    # Find Contributorship
    @contributorship = Contributorship.find(params[:id])
    @person = Person.find_by_id(@contributorship.person_id)
    
    # Update Contributorship
    # 1. Set Contributorship.state to "Denied"
    # 2. Set Contributorship.hide to "true"
    # 3. Set Contributorship.score to "zero"
    @contributorship.update_attributes(:contributorship_state_id => 3, :hide => 1, :score => 0)
    
    # RJS action removes the denied citation from the view
    respond_to do |format|
      format.js { render :action => :deny_contributorship }
    end
  end
end
