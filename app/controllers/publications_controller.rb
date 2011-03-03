class PublicationsController < ApplicationController

  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [ :new, :create, :edit, :update, :destroy ]
  
  make_resourceful do
    build :index, :show, :new, :edit, :create, :update
    
    publish :yaml, :xml, :json, :attributes => [
      :id, :name, :url, :issn_isbn, :publisher_id, {
        :publisher => [:id, :name]
        }, {
        :authority => [:id, :name]
        }, {
        :works => [:id]
        }
      ]
      
    #Add a response for RSS
    response_for :show do |format| 
      format.html  #loads show.html.haml (HTML needs to be first, so I.E. views it by default)
      format.rss  #loads show.rss.rxml
    end

    before :index do
      # find first letter of publication name (in uppercase, for paging mechanism)
      @a_to_z = Publication.letters.collect { |d| d.letter.upcase }
      default_page = @a_to_z.find_index{|i| i > " "} #prevent returning all every title when the name has a value of whitespace
      if params[:q]
        query = params[:q]
        @current_objects = current_objects
      else
        @page = params[:page] || @a_to_z[default_page] 
        @current_objects = Publication.find(
          :all,
          :conditions => ["publications.id = authority_id and upper(name) like ?", "#{@page}%"],
          :order => "upper(name)"
        )
      end
    end

    before :show do
      search(params)
      @publication = @current_object

      @authority_for = Publication.find(
        :all,
        :conditions => ["authority_id = ?", @current_object.id],
        :order => "name"
      )
    end

    before :new do
      #Anyone with 'editor' role (anywhere) can add publications
      permit "editor"
      
      @publishers = Publisher.find(:all, :conditions => ["id = authority_id"], :order => "name")
      @publications = Publication.find(:all, :conditions => ["id = authority_id"], :order => "name")
    end

    before :create do
      #Anyone with 'editor' role (anywhere) can add publications
      permit "editor"
    end
    
    before :edit do
      #Anyone with 'editor' role (anywhere) can update publications
      permit "editor"
      
      @publishers = Publisher.find(:all, :conditions => ["id = authority_id"], :order => "name")
      @publications = Publication.find(:all, :order => "name")
    end
    
    before :update do
      #Anyone with 'editor' role (anywhere) can update publications
      permit "editor"
    end
   
  end

  def authorities
    #Only group editors can assign authorities
    permit "editor of Group"
    
    @a_to_z = Publication.letters.collect { |d| d.letter }
    @page = params[:page] || @a_to_z[0]
    
    if params[:q]
      query = params[:q]
      @current_objects = current_objects
    else
      @current_objects = Publication.find(
        :all, 
        :conditions => ["id = authority_id and name like ?", "#{@page}%"], 
        :order => "upper(name)"
      )
    end

    #Keep a list of publications in process in session[:publication_auths]
    #session[:publication_auths].clear
    @pas = session[:publication_auths] || Array.new
  end

  def add_to_box
    @a_to_z = Publication.letters.collect { |d| d.letter }
    @page = params[:page] || @a_to_z[0]
    #Add new pubs to the list, and to the session var
    @pas = session[:publication_auths] || Array.new
    if params[:new_pa]
      begin
        pa = Publication.find(params[:new_pa])
        @pas << pa.id unless @pas.include?(pa.id)
      rescue ActiveRecord::RecordNotFound
        flash[:warning] = "One or more publications could not be found."
        redirect_to authorities_publications_path
      end
    end
    session[:publication_auths] = @pas
    redirect_to authorities_publications_path(:page => @page) unless request.xhr?
  end

  def remove_from_box
    @a_to_z = Publication.letters.collect { |d| d.letter }
    @page = params[:page] || @a_to_z[0]
    #Remove pubs from the list
    @pas = session[:publication_auths] || Array.new
    if params[:rem_pa]
      begin
        pa = Publication.find(params[:rem_pa])
        @pas.delete(pa.id) if @pas.include?(pa.id)
      rescue ActiveRecord::RecordNotFound
        flash[:warning] = "One or more publications could not be found."
        redirect_to authorities_publications_path
      end
    end
    session[:publication_auths] = @pas
    redirect_to authorities_publications_path(:page => @page) unless request.xhr?
  end
  
  def update_multiple
    #Only system-wide editors can assign authorities
    permit "editor of Group"
    
    pub_ids = params[:pub_ids]
    auth_id = params[:auth_id]
    
    @a_to_z = Publication.letters.collect { |d| d.letter }
    @page = params[:page] || @a_to_z[0]
    
    if auth_id
      update = Publication.update_multiple(pub_ids, auth_id)
      session[:publication_auths] = nil
    else
      flash[:warning] = "You must select one record as the authority."
    end


    respond_to do |wants|
      wants.html do
        redirect_to authorities_publications_path(:page => @page)
      end
    end
  end

  def destroy
    permit "admin"

    publication = Publication.find(params[:id])
    return_path = params[:return_path] || publications_url

    full_success = true

    #Find all works associated with this publication
    works = publication.works

    #Don't allow deletion of publications with works associated
    if works.blank?
      #Destroy the publication
      publication.destroy
    else
      full_success = false
    end

    respond_to do |format|
      if full_success
        flash[:notice] = "Publications were successfully deleted."
        #forward back to path which was specified in params
        format.html {redirect_to return_path }
        format.xml  {head :ok}
      else
        flash[:warning] = "This publication has #{works.length} work associated with it, which must be altered or removed before this publication can be deleted."
        format.html {redirect_to edit_publication_path(publication.id)  }
        format.xml  {head :ok}
      end
    end
  end

  private
  
  def current_objects
    #TODO: If params[:q], handle multiple request types:
    # * ISSN
    # * ISBN
    # * Name (abbreviations)
    # * Publisher
    @current_objects ||= current_model.find_all_by_issn_isbn(params[:q])
  end
end
