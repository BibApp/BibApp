class MembershipsController < ApplicationController
  before_filter :find_membership, :only => [:destroy]
  before_filter :find_person, :only => [:create, :create_group, :new, :destroy, :sort]
  before_filter :find_group,  :only => [:create, :create_group, :destroy]
  
  make_resourceful do 
    build :index, :show, :new, :update
  end
  
  
  def create
    @person.groups << @group  
    respond_to do |format|
      format.js { render :action => :regen_lists }
      format.html { redirect_to new_membership_path(:person_id => @person.id) }
    end
  end
  
  def create_group
    @group = Group.find_or_create_by_name(params[:group][:name])
    
     @membership = Membership.find_by_person_id_and_group_id(
     @person.id,
     @group.id)
    if(@membership == nil)
      @person.groups << @group
      respond_to do |format|
        format.html { redirect_to new_membership_path(:person_id => @person.id) }
        format.js { render :action => :regen_lists }
      end
    end
  end
  
  def destroy
    @membership.destroy if @membership
    respond_to do |format|
      format.js { render :action => :regen_lists }
      format.html { redirect_to new_membership_path(:person_id => @person.id) }
    end

  end
  
  def sort
    @person.groups.each do |group|
      membership = Membership.find_by_person_id_and_group_id(@person.id, group.id)
      membership.position = params["current"].index(group.id.to_s)+1
      membership.save
    end
    
    respond_to do |format|
      format.js { render :action => :regen_lists }
      format.html { redirect_to new_membership_path(:person_id => @person.id) }
    end
  end
  
  def edit_time
    @person = Person.find_by_id(params[:person_id])
    @group = Group.find_by_id(params[:group_id])
    membership = Membership.find(params[:id])
    membership.update_attributes(params[:membership])
    
    render :partial => 'group', :collection => @person.groups(true), :locals => {:selected => true}
    
  end
  
  def auto_complete_for_group_name
    group_name = params[:group][:name].downcase
    
    #search at beginning of name
    beginning_search = group_name + "%"
    #search at beginning of any other words in name
    word_search = "% " + group_name + "%"
    
    groups = Group.find(:all, 
          :conditions => [ "LOWER(name) LIKE ? OR LOWER(name) LIKE ?", beginning_search, word_search ], 
        :order => 'name ASC',
        :limit => 8)
      
    render :partial => 'autocomplete_list', :locals => {:objects => groups}
  end 
  
  
  private
  def find_person
    @person = Person.find_by_id(params[:person_id])
  end
  
  def find_group
    @group = Group.find_by_id(params[:group_id])
  end
  
  def find_membership
    @membership = Membership.find_by_person_id_and_group_id(
      params[:person_id],
      params[:group_id]
    )
  end
end
