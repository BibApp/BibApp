class MembershipsController < ApplicationController

  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy]

  before_filter :find_membership, :only => [:destroy]
  before_filter :find_person, :only => [:create, :create_group, :new, :destroy, :sort, :ajax_sort]
  before_filter :find_group, :only => [:create, :create_group, :destroy]

  make_resourceful do
    build :index, :show, :new, :update

    before :update do
      #'editor' of person or group can update membership details
      permit "editor of person or group"
    end

    before :new do
      @person = Person.find(params[:person_id])
      @title = t('common.memberships.new_title', :name => @person.display_name)

      member = @person.groups.empty? ? "non_member" : "member"
      @status = params[:status] || member

      #For searching groups: AND together like conditions on all pieces of the query
      @query = params[:q]
      rails_query = Group.order_by_name
      if @query
        query_words = @query.downcase.split
        query_words.each do |qw|
          rails_query = rails_query.where("LOWER(name) LIKE ?", "%#{qw}%")
        end
      end
      results = rails_query

      @parents = Array.new
      @groups = Array.new

      # 'results' contains a list of all groups, or all groups returned by the
      # search. We now form two arrays, one for top-level parents, the other
      # for all groups. We will paginate on top-level parents.
      #
      # For each group, check to see if it is a parent:
      # If it has no parents, then it is a parent by default (even if childless)
      # and it goes into the @parents array.
      # If it has a parent, then the parent goes into the @parents array,
      # unless the parent has parents, in which case it is not top-level.
      #
      # Regardless of parent status, all groups go into the @groups array
      # as well as their parent and all their children. That way, if a group
      # with a parent or with children is retrieved from a search, it's parent
      # and children will be returned as well.

      results.each do |g|
        @parents << g.top_level_parent
        @groups << g.ancestors_and_descendants
        @groups << g
      end

      @groups = @groups.flatten.uniq
      @parents.uniq!

      @groups.sort! { |a, b| a.name.downcase <=> b.name.downcase }
      @parents.sort! { |a, b| a.name.downcase <=> b.name.downcase }

    end

  end


  def create
    #'editor' of person or group can create a membership
    permit "editor of person or group"

    @person.groups << @group
    respond_to do |format|
      format.html { redirect_to new_person_membership_path(:person_id => @person.id) }
    end
  end


  def create_multiple

    person = Person.find(params[:person_id])
    group_ids = params[:group_id]

    full_success = true

    unless group_ids.blank?
      #Create each membership one by one, so we can be sure user has 'edit' rights on all
      group_ids.each do |group_id|
        group = Group.find(group_id)

        #One final check...only an editor on this person or group can create the membership
        if logged_in? && (current_user.has_role?("editor", person) || current_user.has_role?("editor", group))
          begin
            person.groups << group
          rescue ActiveRecord::RecordInvalid
            flash[:warning] = t('common.memberships.flash_create_multiple_membership')
          end
        else
          full_success = false
        end
      end
    end

    #Return path for any actions that take place on the memberships page
    return_path = new_person_membership_path(:person_id=>params[:person_id],
                                             :status=>full_success ? 'member' : params[:status])

    respond_to do |format|
      if full_success
        flash[:notice] = t('common.memberships.flash_create_multiple_success')
      else
        flash[:warning] = t('common.memberships.flash_create_multiple_privileges')
      end
      #forward back to path which was specified in params
      format.html { redirect_to return_path }
      format.xml { head :ok }
    end
  end

  def create_group
    #'editor' of person can create new groups
    permit "editor of person"

    @group = Group.find_or_create_by_name(params[:group][:name])
    @group.hide = false
    @group.save

    @membership = Membership.find_by_person_id_and_group_id(@person.id, @group.id)
    unless @membership
      @person.groups << @group
      respond_to do |format|
        format.html { redirect_to new_person_membership_path(:person_id => @person.id) }
      end
    end
  end

  def search_groups
    respond_to do |format|
      format.html { redirect_to new_person_membership_path(:person_id => params[:person_id],
                                                           :status => params[:status], :q => params[:q]) }
    end
  end


  def destroy
    #'editor' of person or group can destroy a membership
    permit "editor of Person or editor of Group"
    @membership = Membership.find(params[:id])
    @membership.destroy if @membership
    respond_to do |format|
      format.html do
        if @membership
          redirect_to new_person_membership_path(:person_id => @membership.person.id)
        else
          redirect_to root_url
        end
      end
    end

  end

  def ajax_sort
    ids = params[:ids].collect { |id| id.split('_').last.to_i }
    @person.transaction do
      ids.each_with_index do |id, position|
        membership = @person.memberships.where(:group_id => id).first
        membership.position = position + 1
        membership.save
      end
    end
    respond_to do |format|
      format.html do
        render :nothing => true
      end
    end
  end

  #TODO - at least some of what this is supposed to do is superseded by ajax_sort. Is it used for anything else,
  #or can it and its route be removed?
  def sort
    @person.groups.each do |group|
      membership = Membership.find_by_person_id_and_group_id(@person.id, group.id)
      membership.position = params["current"].index(group.id.to_s)+1
      membership.save
    end

    respond_to do |format|
      format.html { redirect_to new_membership_path(:person_id => @person.id) }
    end
  end


  def update
    membership = Membership.find(params[:id])
    fix_date_parameters
    membership.update_attributes(params[:membership])
    @person = membership.person
    respond_to do |format|
      format.html { render :partial => 'group', :collection => @person.groups(true) }
      format.js {render :nothing => true}
    end
  end

  private
  def find_person
    @person = Person.find_by_id(params[:person_id])
  end

  def find_group
    @group = Group.find_by_id(params[:group_id])
  end

  def find_membership
    @membership = Membership.find_by_person_id_and_group_id(params[:person_id], params[:group_id])
  end

#for the membership update we're having problems when a non-nil date is updated to be
#blank, which appears to be caused by how Rails handles date through the date-select
#helper and subsequent model side processing. This is to fix that. If a year field
#is blank, we delete all of the partial fields and replace with a whole field set
#to nil
  def fix_date_parameters
    ['start_date', 'end_date'].each do |date_field|
      if params[:membership]["#{date_field}(1i)"].blank?
        params[:membership].keys.select { |k| k.match(/^#{date_field}/) }.each do |key|
          params[:membership].delete(key)
        end
        params[:membership][date_field] = nil
      end
    end
  end

end
