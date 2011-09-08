# Controller which handles assigning roles (i.e. permissions)
# to individual users in BibApp system
class RolesController < ApplicationController

  #Require a user be logged in
  before_filter :login_required

  make_resourceful do
    build :index, :new, :show


    before :index do
      load_authorizable #load the authorizable object this role is assigned to
    end

    before :new do
      load_authorizable #load the authorizable object this role will be assigned to

      #Only admins of the authorizable object can create roles
      permit "admin of authorizable"

      @role_name = params[:name] if params[:name]

      # find first letter of usernames (in uppercase, for paging mechanism)
      @a_to_z = User.letters

      #get current page
      @page = params[:page] || @a_to_z[0]

      #get all objects for that current page
      @current_objects = User.where("upper(email) like ?", "#{@page}%").order('upper(email)')
    end

  end #end make_resourceful

  # Generates the New Administrator form
  def new_admin
    params[:name] = "Admin"
    new
  end

  # Generates the New Editor form
  def new_editor
    params[:name] = "Editor"
    new
  end

  # Adds a user to a given role on an object in the system
  def create
    #get authorizable object from URL
    load_authorizable

    #Only admins of the authorizable object can create roles
    permit "admin of authorizable"

    #get User
    user = User.find(params["user_id"])

    #name of role (e.g. admin, editor, etc.)
    name = params["name"].downcase

    #assign role to user on this authorizable object
    @authorizable.accepts_role name, user

    respond_to do |format|
      if @authorizable
        format.html { redirect_to :back }
      else
        format.html { render :action => "new_" + name }
      end
    end
  end

  # Removes a user from a given role on an object in the system
  def destroy
    #get authorizable object from URL
    load_authorizable

    if @authorizable.is_a?(Class)
      authorizable_type = @authorizable.to_s
      authorizable_id = nil
    else
      authorizable_type = @authorizable.class.to_s
      authorizable_id = @authorizable.id
    end

    #Only admins of the authorizable object can create roles
    permit "admin of authorizable"

    #Get User and Role to remove from
    user = User.find(params["user_id"])
    name = params["name"].downcase

    role = Role.find_by_name_and_authorizable_type_and_authorizable_id(name, authorizable_type, authorizable_id)

    if role
      #delete user from role list
      role.users.delete(user)

      #destroy role, if no users attached to it
      role.destroy if role.users(true).empty?
    end

    respond_to do |format|
      format.html { redirect_to :back }
    end
  end

  ###
  # Private Methods
  ###
  private
  #Load the authorizable object which this role is assigned to
  def load_authorizable
    # Currently Roles only are assigned to System, Groups or People
    if params[:authorizable_type] and params[:authorizable_id]
      klass = params[:authorizable_type].constantize #change into a class
      @authorizable = klass.find(params[:authorizable_id])
    elsif params[:authorizable_type] #if no ID, authorizable obj is a Class
      @authorizable = params[:authorizable_type].constantize #change into a class
    elsif params[:group_id]
      @authorizable = Group.find(params[:group_id])
    elsif params[:person_id]
      @authorizable = Person.find(params[:person_id])
    else
      @authorizable = System
    end
  end
end
