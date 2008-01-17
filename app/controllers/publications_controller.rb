class PublicationsController < ApplicationController

  make_resourceful do 
    build :all
    
    publish :yaml, :xml, :json, :attributes => [
      :id, :name, :url, :issn_isbn, :publisher_id, {
        :publisher => [:id, :name]
        }
      ]
    
    before :new, :edit do
      @publishers = Publisher.find(:all, :conditions => ["id = authority_id"], :order => "name")
      @publications = Publication.find(:all, :conditions => ["id = authority_id"], :order => "name")
    end
    
    before :index do
      if params[:q]
        query = params[:q]
        @current_objects = current_objects
      else
        @current_objects = Publication.paginate(
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
        :conditions => ["publication_id = ? and citation_state_id = ?", current_object.id, 3],
        :order => "year DESC, title_primary",
        :page => params[:page] || 1,
        :per_page => 10
      )
      
      @authority_for = Publication.find(
        :all,
        :conditions => ["authority_id = ?", current_object.id],
        :order => "name"
      )
    end
    
    after :update do
      #TODO: Pass this off to an AsyncObserver
      current_object.citations.each do |c|
        c.publication = current_object.authority
        c.publisher = current_object.publisher
        c.save
      end
    end
  end
  
  def current_objects
    @current_objects ||= current_model.find_all_by_issn_isbn(params[:q])
  end
  
end
