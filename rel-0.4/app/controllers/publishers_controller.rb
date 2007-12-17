class PublishersController < ApplicationController
  make_resourceful do 
    build :all
    
    before :new, :edit do
      @publishers = Publisher.find(:all, :conditions => ["id = authority_id"], :order => "name")
      @publications = Publication.find(:all, :conditions => ["id = authority_id"], :order => "name")
    end

    before :index do
      @publishers = Publisher.paginate(
        :all, 
        :conditions => ["id = authority_id"], 
        :order => "name",
        :page => params[:page] || 1,
        :per_page => 10
      )  
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
    
    after :update do
      current_object.citations.each do |c|
        c.publisher = current_object.authority
        c.save
      end
    end
       
    response_for :index do |format|
      format.html # index.html
      format.xml { render :xml => @publishers.to_xml }
    end
    
    response_for :show do |format|
      format.html # index.html
      format.xml { render :xml => @publisher.to_xml }
    end
  end
end
