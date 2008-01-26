class PublishersController < ApplicationController

  make_resourceful do 
    build :index, :show

    publish :yaml, :xml, :json, :attributes => [
      :id, :name, :url, :sherpa_id, :romeo_color, :copyright_notice, :publisher_copy, {
        :publications => [:id, :name]
        }
      ]

    before :index do
      if params[:q]
        query = params[:q]
        @current_objects = current_objects
      else
        @current_objects = Publisher.paginate(
          :all, 
          :conditions => ["id = authority_id"], 
          :order => "name",
          :page => params[:page] || 1,
          :per_page => 20
        )
      end
    end
    
    before :show do
      @citations = Citation.paginate(
        :all,
        :conditions => ["publisher_id = ? and citation_state_id = ?", current_object.id, 3],
        :order => "year DESC, title_primary",
        :page => params[:page] || 1,
        :per_page => 10
      )
        
      @authority_for = Publisher.find(
        :all,
        :conditions => ["authority_id = ?", current_object.id],
        :order => "name"
      )
    end
  end
  
  def current_objects
    if params[:q]
      query = '%' + params[:q] + '%'
    end
    @current_objects ||= current_model.find(:all, :conditions => ["name like ?", query])
  end
end
