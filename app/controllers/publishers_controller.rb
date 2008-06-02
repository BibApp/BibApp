class PublishersController < ApplicationController

  make_resourceful do 
    build :index, :show, :new, :edit, :create, :update

    publish :yaml, :xml, :json, :attributes => [
      :id, :name, :url, :sherpa_id, :romeo_color, :copyright_notice, :publisher_copy, {
        :publications => [:id, :name]
        }, {
        :authority => [:id, :name]
        }, {
        :citations => [:id]
        }
      ]

    before :index do
      @a_to_z = Publisher.letters.collect { |d| d.letter }
      
      if params[:q]
        query = params[:q]
        @current_objects = current_objects
      else
        @page = params[:page] || @a_to_z[0]
        @current_objects = Publisher.find(:all, :conditions => ["id = authority_id and name like ?", "#{@page}%"], :order => "name")
      end
    end

    before :show do
      @authority_for = Publisher.find(
        :all,
        :conditions => ["authority_id = ?", current_object.id],
        :order => "name"
      )

      @query = @current_object.solr_id
      @filter = params[:fq] || ""
      @filter = @filter.split("+>+").each{|f| f.strip!}
      @sort = params[:sort] || "year"
      @page = params[:page] || 0
      @count = params[:count] || 10
      
      @q,@docs,@facets = Index.fetch(@query, @filter, @sort, @page, @count)
      @view = "all"
      @title = @current_object.name
    end

    before :new, :edit do
      @publishers = Publisher.find(:all, :conditions => ["id = authority_id"], :order => "name")
      @publications = Publication.find(:all, :conditions => ["id = authority_id"], :order => "name")
    end
  end
  
  def authorities
    @a_to_z = Publisher.letters.collect { |d| d.letter }
    
    if params[:q]
      query = params[:q]
      @current_objects = current_objects
    else
      @page = params[:page] || @a_to_z[0]
      @current_objects = Publisher.find(:all, :conditions => ["id = authority_id and name like ?", "#{@page}%"], :order => "name")
    end    
  end

  def update_multiple
    pub_ids = params[:pub_ids]
    auth_id = params[:auth_id]
    page = params[:page]
    
    update = Publisher.update_multiple(pub_ids, auth_id)

    respond_to do |wants|
      wants.html do
        redirect_to authorities_publishers_path(:page => page)
      end
    end
  end

  private
  def current_objects
    if params[:q]
      query = '%' + params[:q] + '%'
    end
    @current_objects ||= current_model.find(:all, :conditions => ["name like ?", query])
  end
end