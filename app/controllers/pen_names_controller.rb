class PenNamesController < ApplicationController
  before_filter :find_pen_name, :only => [:destroy]
  before_filter :find_person, :only => [:create, :create_author_string, :new, :destroy, :sort]
  before_filter :find_author_string,  :only => [:create, :create_author_string, :destroy]

  make_resourceful do 
    build :index, :show, :new, :update
  end


  def create
    @person.author_strings << @author_string
    respond_to do |format|
      format.js { render :action => :regen_lists }
      format.html { redirect_to new_pen_name_path(:person_id => @person.id) }
    end
  end

  def create_author_string
    @author = AuthorString.find_or_create_by_name(params[:author_string][:name])
    @person.author_strings << @author_string
    respond_to do |format|
      format.html { redirect_to new_pen_name_path(:person_id => @person.id) }
      format.js { render :action => :regen_lists }
    end
  end

  def destroy
    @pen_name.destroy if @pen_name
    respond_to do |format|
      format.js { render :action => :regen_lists }
      format.html { redirect_to new_pen_name_path(:person_id => @person.id) }
    end
  end

  def sort
    @person.pen_names.each do |pen_name|
      pen_name = PenName.find_by_person_id_and_author_string_id(@person.id, pen_name.id)
      pen_name.position = params["current"].index(pen_name.id.to_s)+1
      pen_name.save
    end

    respond_to do |format|
      format.js { render :action => :regen_lists }
      format.html { redirect_to new_pen_name_path(:person_id => @person.id) }
    end
  end

  def live_search_for_author_strings
    @phrase = params[:q]
    a1 = "%"
    a2 = "%"
    @searchphrase = a1 + @phrase + a2
    @results = AuthorString.find(:all, :conditions => [ "name LIKE ?", @searchphrase], :order => "name")
    @number_match = @results.length
    @person = Person.find(params[:person_id])
    @results = @results - @person.author_strings
        
    respond_to do |format|
      format.js { render :action => :author_string_filter }
      format.html { redirect_to new_pen_name_path(:person_id => @person.id) }
    end
  end

  private
  def find_person
    @person = Person.find_by_id(params[:person_id])
  end

  def find_author_string
    @author_string = AuthorString.find_by_id(params[:author_string_id])
  end

  def find_pen_name
    @pen_name = PenName.find_by_person_id_and_author_string_id(
      params[:person_id],
      params[:author_string_id]
    )
  end
  
end