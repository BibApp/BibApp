class MembershipsController < ApplicationController
  before_filter :find_membership, :only => [:destroy]
  before_filter :find_group, :only => [:create, :destroy]
  before_filter :find_person, :only => [:create, :destroy, :new, :create_group]
  
  def create
    @person.groups << @group
    respond_to do |format|
      format.js { render :action => :regen_lists }
      format.html { redirect_to :action => new, :person_id => @person.id }
    end
    
  end
  
  def destroy
    @membership.destroy if @membership
    respond_to do |format|
      format.js { render :action => :regen_lists }
      format.html { redirect_to :action => new, :person_id => @person.id }
    end
  end
  
  def create_group
    @group = Group.find_or_create_by_name(params[:group][:name])
    @person.groups << @group
    respond_to do |format|
      format.html { redirect_to new_membership_path(:person_id => @person.id) }
      format.js { render :action => :regen_lists }
    end
  end
  
  def new
  end

  private
  def find_person
    @person ||= Person.find(params[:person_id])
  end
  
  def find_group
    @group ||= Group.find(params[:group_id])
  end
  
  def find_membership
    @membership = Membership.find_by_person_id_and_group_id(
      params[:person_id],
      params[:group_id]
    )
  end
end
