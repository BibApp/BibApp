class ContributorshipsController < ApplicationController
  
  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [ :new, :create, :edit, :update, :destroy ]
  
  make_resourceful do
    build :index
    
    before :index do
      if params[:person_id]
        @person = Person.find(params[:person_id])
        @page   = params[:page] || 1
        @status = params[:status] || "unverified"
        
        @contributorships = @person.contributorships.send(@status).paginate(
          :page => params[:page] || 1,
          :per_page => 10
        )
        
      end
    end
  end
  
  def admin
    
    #find all visible, unverified contributorships
    @unverified = Contributorship.unverified.visible
    
    @contributorship = @unverified.first
    
    if @contributorship == nil
      # Do Nothing
    else
      @claims = Contributorship.unverified.visible.find(
        :all, 
        :conditions => ["citation_id = ?", @contributorship.citation_id],
        :order => "score desc"
      )
    end
  end
  
  def verify
    @contributorship = Contributorship.find(params[:id])
    person = @contributorship.person
    
    # only 'editor' of this person can verify contributorship   
    permit "editor of :person", :person => person
    
    @contributorship.update_attributes(:contributorship_state_id => 2)
    person.update_scoring_hash
    
    @contributorship.person.contributorships.unverified.each do |c|
      c.calculate_score
    end
    
    @contributorships = person.contributorships.to_show
    
    respond_to do |format|
      format.html { redirect_to :back }
      format.js   { render :action => :verify_contributorship }
    end
  end
  
  def deny
    # Find Contributorship
    @contributorship = Contributorship.find(params[:id])
    @person = Person.find_by_id(@contributorship.person_id)
    
    # only 'editor' of this person can deny contributorship   
    permit "editor of person"
    
    # Update Contributorship
    # 1. Set Contributorship.state to "Denied"
    # 2. Set Contributorship.hide to "true"
    # 3. Set Contributorship.score to "zero"
    @contributorship.update_attributes(:contributorship_state_id => 3, :hide => 1, :score => 0)
    
    # RJS action removes the denied citation from the view
    respond_to do |format|
      format.html { redirect_to :back }
      format.js   { render :action => :deny_contributorship }
    end
  end
  
  def archivable
    # Find Person for view
    @person = Person.find(params[:person_id])
    
    # Collect data for Sherpa color table
    @pub_table = romeo_color_count
    
    # Calculate the sum of each Sherpa color
    @pub_totals = @pub_table.collect{|c| c.count}.inject{|sum, n| sum.to_i + n.to_i}
    
    # Collect data for Publication table
    @publ_table = publication_count
  end
  
  private
  
  def romeo_color_count
    # Build query which groups all citations (of this person) 
    # under appropriate Romeo Colors (based on publisher)
    # and retrieves a total number of each Romeo Color.
    Contributorship.all(:select => "count(contributorships.id) as count, publishers.romeo_color as color", 
                         :joins => "JOIN citations ON contributorships.citation_id=citations.id
                                    JOIN people ON contributorships.person_id=people.id
                                    JOIN publishers ON citations.publisher_id=publishers.id",
                         :conditions => ["people.id = ?", @person.id],
                         :group => "publishers.romeo_color",
                         :order => "publishers.romeo_color")
  end
  
  
  def publication_count
    # Build query which groups all citations (of this person) 
    # by the Journal/Publication and Publisher
    # and retrieves a total number of each Journal/Publication
    Contributorship.all(:select => "count(contributorships.id) as count, publications.name as name, publishers.name as pub_name, publishers.romeo_color as color", 
                         :joins => "JOIN citations ON contributorships.citation_id=citations.id
                                    JOIN people ON contributorships.person_id=people.id
                                    JOIN publications ON citations.publication_id = publications.id
                                    JOIN publishers ON citations.publisher_id=publishers.id",
                         :conditions => ["people.id = ?", @person.id],
                         :group => "publications.name, publishers.name, publishers.romeo_color",
                         :order => "count(contributorships.id) desc")
  end
  
end
