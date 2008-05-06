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
  
  def admin
    @contributorship = Contributorship.find(
      :first, 
      :conditions => ["contributorship_state_id = ? and hide = ?", 1, false],
      :order => "citation_id"
    )
    
    if @contributorship == nil
      # Do Nothing
    else
      @claims = Contributorship.find(
        :all, 
        :conditions => ["citation_id = ? and contributorship_state_id = ? and hide = ?", @contributorship.citation_id, 1, false],
        :order => "score desc"
      )
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
      format.html { redirect_to :action => :admin }
      format.js   { render :action => :verify_contributorship }
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
      format.html { redirect_to :action => :admin }
      format.js   { render :action => :deny_contributorship }
    end
  end
  
  def archivable
    # Find Person for view
    @person = Person.find(params[:person_id])
    
    # Collect data for Sherpa color table
    @pub_table = Contributorship.find_by_sql(
      ["select count(ctrb.id) as count, pub.romeo_color as color
      from contributorships ctrb
      join citations c on ctrb.citation_id = c.id
      join people p on ctrb.person_id = p.id
      join publishers pub on c.publisher_id = pub.id
      where p.id = ?
      group by pub.romeo_color
      order by pub.romeo_color", @person.id]
    )
    
    # Calculate the sum of each Sherpa color
    @pub_totals = @pub_table.collect{|c| c.count}.inject{|sum, n| sum.to_i + n.to_i}
    
    # Collect data for Publication table
    @publ_table = Contributorship.find_by_sql(
        ["select count(ctrb.id) as count, publ.name as name, pub.name as pub_name, pub.romeo_color as color
        from contributorships ctrb
        join citations c on ctrb.citation_id = c.id
        join people p on ctrb.person_id = p.id
        join publications publ on c.publication_id = publ.id
        join publishers pub on c.publisher_id = pub.id
        where p.id = ?
        group by publ.name
        order by count(ctrb.id) desc", @person.id]
      )
    
  end
end
