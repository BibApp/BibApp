class NameStringsController < ApplicationController
  
  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [ :new, :create, :edit, :update, :destroy ]
  
  make_resourceful do 
    build :all
    
    before :index do
      @a_to_z = NameString.letters.collect { |d| d.letter }
      
      @page = params[:page] || @a_to_z[0]
      @current_objects = NameString.where("upper(name) like ?", "#{@page}%").order('upper(name)')
    end
    
    response_for :index do |format|
      format.html # index.html
      format.xml { render :xml => @name_strings.to_xml }
    end

    before :show do
      
    end
    
    response_for :show do |format|
      format.html # index.html
      format.xml { render :xml => @name_string.to_xml }
    end
  end
end
