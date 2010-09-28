class ContributorshipsController < ApplicationController
  
  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [ :new, :create, :edit, :update, :destroy ]
  
  make_resourceful do
    build :index
    
    before :index do
      if params[:person_id]
        @person = Person.find(params[:person_id])
        @page   = params[:page] || 1
        @rows = params[:rows] || 10
        @status = params[:status] || "unverified"
        
        @contributorships = @person.contributorships.send(@status).paginate(
          :page => @page,
          :per_page => @rows,
          :include => [:work],
          :order => 'works.publication_date desc'
        )
      else
        render :controller => "application", :action => "error_404"
      end
    end
  end
  
  def admin

    @people = Contributorship.unverified.visible.group_by{|c| c.person_id}
    t = true
  end

  def verify_multiple
    # Anyone who is minimally an admin (on anything in system) can verify
    # contributorships
    #permit "admin"

    contrib_ids = params[:contrib_id]
    full_success = true

    unless contrib_ids.nil? or contrib_ids.empty?
      #Destroy each work one by one, so we can be sure user has 'admin' rights on all
      contrib_ids.each do |contrib_id|
        contributorship = Contributorship.find(contrib_id)

        #One final check...only an admin on this contributorship can verify it
#        if logged_in? && current_user.has_role?("admin", contributorship)
#          contributorship.verify_contributorship
#        else
#          full_success = false
#        end
        contributorship.verify_contributorship
      end
    end
    
    #Return path for any actions that take place on the contributorships page
    return_path = contributorships_path(:person_id=>params[:person_id],
                                        :status=>params[:status])

    respond_to do |format|
      if full_success
        flash[:notice] = "Contributorships were successfully verified."
      else
        flash[:warning] = "One or more contributorships could not be verified; you have insufficient privileges"
      end
      #forward back to path which was specified in params
      format.html {redirect_to return_path }
      format.xml  {head :ok}
    end
  end

  def unverify_multiple
    #Anyone who is minimally an admin (on anything in system) can unverify
    #       contributorships
    #permit "admin"

    contrib_ids = params[:contrib_id]

    full_success = true

    unless contrib_ids.nil? or contrib_ids.empty?
      #Destroy each work one by one, so we can be sure user has 'admin' rights on all
      contrib_ids.each do |contrib_id|
        contributorship = Contributorship.find(contrib_id)

        #One final check...only an admin on this contributorship can verify it
#        if logged_in? && current_user.has_role?("admin", contributorship)
#          contributorship.unverify_contributorship
#          contributorship.save
#        else
#          full_success = false
#        end
        contributorship.unverify_contributorship
        contributorship.save
      end
    end

    #Return path for any actions that take place on the contributorships page
    return_path = contributorships_path(:person_id=>params[:person_id],
                                        :status=>params[:status])

    respond_to do |format|
      if full_success
        flash[:notice] = "Contributorships were successfully unverified."
      else
        flash[:warning] = "One or more contributorships could not be unverified; you have insufficient privileges"
      end
      #forward back to path which was specified in params
      format.html {redirect_to return_path }
      format.xml  {head :ok}
    end
  end

  def deny_multiple
    #Anyone who is minimally an admin (on anything in system) can verify
    #       contributorships
    #permit "admin"

    contrib_ids = params[:contrib_id]

    full_success = true

    unless contrib_ids.nil? or contrib_ids.empty?
      #Destroy each work one by one, so we can be sure user has 'admin' rights on all
      contrib_ids.each do |contrib_id|
        contributorship = Contributorship.find(contrib_id)

        #One final check...only an admin on this contributorship can verify it
#        if logged_in? && current_user.has_role?("admin", contributorship)
#          contributorship.deny_contributorship
#          contributorship.save
#        else
#          full_success = false
#        end
        contributorship.deny_contributorship
        contributorship.save
      end
    end

    #Return path for any actions that take place on the contributorships page
    return_path = contributorships_path(:person_id=>params[:person_id],
                                        :status=>params[:status])

    respond_to do |format|
      if full_success
        flash[:notice] = "Contributorships were successfully denied."
      else
        flash[:warning] = "One or more contributorships could not be denied; you have insufficient privileges"
      end
      #forward back to path which was specified in params
      format.html {redirect_to return_path }
      format.xml  {head :ok}
    end
  end
  
  def verify
    @contributorship = Contributorship.find(params[:id])
    person = @contributorship.person
    
    # only 'editor' of this person can verify contributorship   
    permit "editor of :person", :person => person
    
    #Verify & save contributorship
    #(Note: Contributorship callbacks will automatically update scores, etc.)
    @contributorship.verify_contributorship
    @contributorship.save
    
    #get updated list of contributorships to display
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
    
    @contributorship.deny_contributorship
    @contributorship.save
   
    # RJS action removes the denied Work from the view
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
    # Build query which groups all Works (of this person) 
    # under appropriate Romeo Colors (based on publisher)
    # and retrieves a total number of each Romeo Color.
    Contributorship.verified.all(
                         :select => "count(contributorships.id) as count, publishers.romeo_color as color", 
                         :joins => "JOIN works ON contributorships.work_id=works.id
                                    JOIN people ON contributorships.person_id=people.id
                                    JOIN publishers ON works.publisher_id=publishers.id",
                         :conditions => ["people.id = ?", @person.id],
                         :group => "publishers.romeo_color",
                         :order => "publishers.romeo_color")
  end
  
  
  def publication_count
    # Build query which groups all works (of this person) 
    # by the Journal/Publication and Publisher
    # and retrieves a total number of each Journal/Publication
    Contributorship.verified.all(
                         :select => "count(contributorships.id) as count, publications.name as name, publishers.name as pub_name, publishers.romeo_color as color, publishers.publisher_copy as pub_copy",
                         :joins => "JOIN works ON contributorships.work_id=works.id
                                    JOIN people ON contributorships.person_id=people.id
                                    JOIN publications ON works.publication_id = publications.id
                                    JOIN publishers ON works.publisher_id=publishers.id",
                         :conditions => ["people.id = ?", @person.id],
                         :group => "publications.name, publishers.name, publishers.romeo_color, publishers.publisher_copy",
                         :order => "count(contributorships.id) desc")
  end
  
end
