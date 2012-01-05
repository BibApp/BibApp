class ContributorshipsController < ApplicationController

  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy]

  make_resourceful do
    build :index

    before :index do
      if params[:person_id]
        @person = Person.find(params[:person_id])
        @page = params[:page] || 1
        @rows = params[:rows] || 10
        @status = params[:status] || "unverified"
        #Don't want to allow an arbitrary send to @person.contributorships below - e.g. params[:status] = 'clear'
        @status = 'unverified' unless ['unverified', 'verified', 'denied'].member?(@status.to_s)
        @title = t('common.contributorships.index_title', :display_name => @person.display_name,
                   :status => t("common.contributorships.#{@status}").capitalize)
        @contributorships = @person.contributorships.send(@status).includes(:work).
            order('works.publication_date_year desc, works.publication_date_month desc, works.publication_date_day desc').paginate(:page => @page, :per_page => @rows)
      else
        render :status => 404
      end
    end
  end

  def admin
    @people = Contributorship.unverified.visible.group_by { |c| c.person_id }
    true
  end

  def act_on_multiple
    action = params[:do_to_all]
    if ['verify', 'unverify', 'deny'].include?(action)
      self.send(:"#{action}_multiple") and return
    end
    redirect_to contributorships_path(:person_id=>params[:person_id], :status=>params[:status])
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
    end
  end

  def deny
    # Find Contributorship
    @contributorship = Contributorship.find(params[:id])
    @person = @contributorship.person

    # only 'editor' of this person can deny contributorship
    permit "editor of person"

    @contributorship.deny_contributorship
    @contributorship.save

    respond_to do |format|
      format.html { redirect_to :back }
    end
  end

  def archivable
    # Find Person for view
    @person = Person.find(params[:person_id])
    @title = t('common.contributorships.archivable_title', :display_name => @person.display_name)

    # Collect data for Sherpa color table
    @pub_table = romeo_color_count

    # Calculate the sum of each Sherpa color
    @pub_totals = @pub_table.collect { |c| c.count }.inject { |sum, n| sum.to_i + n.to_i }

    # Collect data for Publication table
    @publ_table = publication_count
  end

  private

  def romeo_color_count
    # Build query which groups all Works (of this person)
    # under appropriate Romeo Colors (based on publisher)
    # and retrieves a total number of each Romeo Color.
    Contributorship.verified.for_person(@person).
        select("count(contributorships.id) as count, publishers.romeo_color as color").
        joins({:work => :publisher}, :person).
        group("publishers.romeo_color").
        order("publishers.romeo_color")
  end


  def publication_count
    # Build query which groups all works (of this person)
    # by the Journal/Publication and Publisher
    # and retrieves a total number of each Journal/Publication
    Contributorship.verified.for_person(@person).
        select("count(contributorships.id) as count, publications.name as name, publishers.name as pub_name,
                publishers.romeo_color as color, publishers.publisher_copy as pub_copy").
        joins({:work => [:publisher, :publication]}, :person).
        group("publications.name, publishers.name, publishers.romeo_color, publishers.publisher_copy").
        order("count(contributorships.id) desc")
  end

  protected

  def act_on_many(action, flash_action)
    Contributorship.find(params[:contrib_id]).each do |contributorship|
      contributorship.send(action)
    end
    respond_to do |format|
      flash[:notice] = t('common.contributorships.flash_act_on_many', :action => t("common.contributorships.#{flash_action}"))
      #forward back to path which was specified in params
      format.html { redirect_to contributorships_path(:person_id=>params[:person_id], :status=>params[:status]) }
      format.xml { head :ok }
    end
  end

  def verify_multiple
    act_on_many(:verify_contributorship, 'verified')
  end

  def unverify_multiple
    act_on_many(:unverify_contributorship, 'unverified')
  end

  def deny_multiple
    act_on_many(:deny_contributorship, 'denied')
  end

end
