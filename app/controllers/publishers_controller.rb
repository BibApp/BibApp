class PublishersController < ApplicationController

  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy]

  make_resourceful do
    build :index, :show, :new, :edit, :create, :update

    publish :yaml, :xml, :json, :attributes => [
            :id, :name, :url, :sherpa_id, :romeo_color, :copyright_notice, :publisher_copy, {
                    :publications => [:id, :name]
            }, {
                    :authority => [:id, :name]
            }, {
                    :works => [:id]
            }
    ]

    #Add a response for RSS
    response_for :show do |format|
      format.html #loads show.html.haml (HTML needs to be first, so I.E. views it by default)
      format.rss #loads show.rss.rxml
    end

    response_for :update do |format|
      format.html do
        if params[:save_and_list]
          redirect_to publishers_url(:page => @publisher.name.first.upcase)
        else
          redirect_to publisher_url(@publisher)
        end
      end
      format.rss
    end

    before :index do
      # find first letter of publisher name (in uppercase, for paging mechanism)
      @a_to_z = Publisher.letters(true)

      @authorities = Publisher.authorities.upper_name_like("%#{params[:search]}%")

      if params[:q]
        query = params[:q]
        @current_objects = current_objects
      else
        @page = params[:page] || @a_to_z[0]
        @current_objects = Publisher.includes(:publications => :works).authorities.upper_name_like("#{@page}%").order_by_upper_name
      end
    end

    before :show do
      search(params)
      @publication = @current_object

      @authority_for = Publisher.for_authority(current_object.id).order_by_name
    end

    before :new do
      #Anyone with 'editor' role (anywhere) can add publishers
      permit "editor"

      @publishers = Publisher.authorities.order_by_name
      @publications = Publication.authorities.order_by_name
    end

    before :create do
      #Anyone with 'editor' role (anywhere) can add publishers
      permit "editor"
    end

    before :edit do
      #Anyone with 'editor' role (anywhere) can update publishers
      permit "editor"

      @publishers = Publisher.order_by_name
      @publications = Publication.authorities.order_by_name
    end

    before :update do
      #Anyone with 'editor' role (anywhere) can update publishers
      permit "editor"
    end
  end

  def authorities
    #Only group editors can assign authorities
    permit "editor of Group"

    @a_to_z = Publisher.letters

    if params[:q]
      query = params[:q]
      @current_objects = current_objects
    else
      @page = params[:page] || @a_to_z[0]
      @current_objects = Publisher.authorities.name_like("#{@page}%").order_by_name.
              includes(:publications, :publisher_source)
    end

    #Keep a list of publications in process in session[:publication_auths]
    @pas = Publisher.includes(:publications, :publisher_source, :authority).find(session[:publisher_auths] || Array.new)
  end

  def add_to_box
    @a_to_z = Publisher.letters
    @page = params[:page] || @a_to_z[0]
    #Add new pubs to the list, and to the session var
    @pas = session[:publisher_auths] || Array.new
    if params[:new_pa]
      begin
        pa = Publisher.find(params[:new_pa])
        @pas << pa.id unless @pas.include?(pa.id)
      rescue ActiveRecord::RecordNotFound
        flash[:warning] = "One or more publications could not be found."
        redirect_to authorities_publishers_path
      end
    end
    session[:publisher_auths] = @pas
    redirect_to authorities_publishers_path(:page => @page) unless request.xhr?
  end

  def remove_from_box
    @a_to_z = Publisher.letters
    @page = params[:page] || @a_to_z[0]
    #Remove pubs from the list
    @pas = session[:publisher_auths] || Array.new
    if params[:rem_pa]
      begin
        pa = Publisher.find(params[:rem_pa])
        @pas.delete(pa.id) if @pas.include?(pa.id)
      rescue ActiveRecord::RecordNotFound
        flash[:warning] = "One or more publications could not be found."
        redirect_to authorities_publishers_path
      end
    end
    session[:publisher_auths] = @pas
    redirect_to authorities_publishers_path(:page => @page) unless request.xhr?
  end

  def update_multiple
    #Only system-wide editors can assign authorities
    permit "editor of Group"

    pub_ids = params[:pub_ids]
    auth_id = params[:auth_id]

    @a_to_z = Publication.letters
    @page = params[:page] || @a_to_z[0]

    if params[:cancel]
      session[:publisher_auths] = nil
      flash[:notice] = "Cancelled authority selection."
    else
      if auth_id
        update = Publisher.update_multiple(pub_ids, auth_id)
        session[:publisher_auths] = nil
      else
        flash[:warning] = "You must select one record as the authority."
      end
    end
    respond_to do |wants|
      wants.html do
        redirect_to authorities_publishers_path(:page => @page)
      end
    end
  end

  private

  def current_objects
    if params[:q]
      query = '%' + params[:q] + '%'
    end
    @current_objects ||= current_model.name_like(query)
  end
end