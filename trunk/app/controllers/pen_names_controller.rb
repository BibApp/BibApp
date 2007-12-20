class PenNamesController < ApplicationController
  before_filter :find_pen_name, :only => [:destroy]
  before_filter :find_person, :only => [:create, :create_author, :new, :destroy, :sort]
  before_filter :find_author,  :only => [:create, :create_author, :destroy]

  make_resourceful do 
    build :index, :show, :new, :update
  end


  def create
    @person.authors << @author
    respond_to do |format|
      format.js { render :action => :regen_lists }
      format.html { redirect_to new_pen_name_path(:person_id => @person.id) }
    end
  end

  def create_author
    @author = Author.find_or_create_by_name(params[:author][:name])
    @person.authors << @author
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
      pen_name = PenName.find_by_person_id_and_author_id(@person.id, pen_name.id)
      pen_name.position = params["current"].index(pen_name.id.to_s)+1
      pen_name.save
    end

    respond_to do |format|
      format.js { render :action => :regen_lists }
      format.html { redirect_to new_pen_name_path(:person_id => @person.id) }
    end
  end

  def live_search_for_authors
    @phrase = params[:q]
    a1 = "%"
    a2 = "%"
    @searchphrase = a1 + @phrase + a2
    @results = Author.find(:all, :conditions => [ "name LIKE ?", @searchphrase], :order => "name")
    @number_match = @results.length
    @person = Person.find(params[:person_id])
    @results = @results - @person.authors
        
    respond_to do |format|
      format.js { render :action => :author_filter }
      format.html { redirect_to new_pen_name_path(:person_id => @person.id) }
    end
  end

  private
  def find_person
    @person = Person.find_by_id(params[:person_id])
  end

  def find_author
    @author = Author.find_by_id(params[:author_id])
  end

  def find_pen_name
    @pen_name = PenName.find_by_person_id_and_author_id(
      params[:person_id],
      params[:author_id]
    )
  end
  
end
