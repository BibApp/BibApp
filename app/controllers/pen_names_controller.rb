class PenNamesController < ApplicationController

  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy]

  before_filter :find_pen_name, :only => [:destroy]
  before_filter :find_person, :only => [:create, :create_name_string, :new, :destroy, :sort]
  before_filter :find_name_string, :only => [:create, :create_name_string, :destroy]

  make_resourceful do
    build :index, :show, :new, :update

    before :new do
      #only 'editor' of person can assign a pen name
      permit "editor of person"

      @suggestions = NameString.name_like(@person.last_name).order_by_name

    end

    before :update do
      #only 'editor' of person can assign a pen name
      permit "editor of person"
    end
  end


  def create
    #only 'editor' of person can assign a pen name
    permit "editor of person"


    logger.debug("\n\n\n\n\n\n\n\n\n\n==== Params: #{params.inspect}")

    if params[:reload]
      @reload = true
    end

    logger.debug("\n\n\n\n\n\n\n\n\n\n==== reload? #{@reload.inspect}")

    @person.name_strings << @name_string
    respond_to do |format|
      format.js { render :action => :regen_lists }
      format.html { redirect_to new_pen_name_path(:person_id => @person.id) }
    end
  end

  def create_name_string
    #only 'editor' of person can assign a pen name
    permit "editor of person"

    name = params[:name_string][:name]
    machine_name = name.mb_chars.gsub(/[\W]+/, " ").strip.downcase

    @name_string = NameString.find_or_create_by_machine_name(machine_name)
    @name_string.name = name
    @name_string.save

    @person.name_strings << @name_string unless @person.name_strings.include?(@name_string)
    respond_to do |format|
      format.html { redirect_to new_pen_name_path(:person_id => @person.id) }
      format.js { render :action => :regen_lists }
    end
  end

  def destroy
    #only 'editor' of person can destroy a pen name
    permit "editor of :person", :person => @pen_name.person

    if params[:reload]
      @reload = true
    end

    @pen_name.destroy if @pen_name
    respond_to do |format|
      format.js { render :action => :regen_lists }
      format.html { redirect_to new_pen_name_path(:person_id => @person.id) }
    end
  end

  def sort
    @person.pen_names.each do |pen_name|
      pen_name = PenName.find_by_person_id_and_name_string_id(@person.id, pen_name.id)
      pen_name.position = params["current"].index(pen_name.id.to_s)+1
      pen_name.save
    end

    respond_to do |format|
      format.js { render :action => :regen_lists }
      format.html { redirect_to new_pen_name_path(:person_id => @person.id) }
    end
  end

  def live_search_for_name_strings
    @phrase = params[:q]
    @person = Person.find(params[:person_id])
    a1 = "%"
    a2 = "%"
    @searchphrase = a1 + @phrase + a2

    #Hack for postgresql, for which LIKE is case-sensitive
    #Alternately, one might view this as a hack for dbs where LIKE is _not_ case sensitive
    #It's not clear to me that the SQL standard is definitive on this - for more evidence,
    #Oracle also seems to be case sensitive, and DB2 seems to depend on individual database settings
    #TODO: is there a better way?
    if @person.configurations[Rails.env]['adapter'] == "postgresql"
      @results = NameString.where("name ILIKE ? OR name ILIKE ?", @searchphrase, "%" + @person.last_name + "%").order_by_name
    else
      @results = NameString.where("name LIKE ? OR name LIKE ?", @searchphrase, "%" + @person.last_name + "%").order_by_name
    end

    @number_match = @results.length
    @results = @results - @person.name_strings

    respond_to do |format|
      format.js { render :action => :name_string_filter }
      format.html { redirect_to new_pen_name_path(:person_id => @person.id) }
    end
  end

  private
  def find_person
    @person = Person.find_by_id(params[:person_id])
  end

  def find_name_string
    @name_string = NameString.find_by_id(params[:name_string_id])
  end

  def find_pen_name
    if params[:id].blank? and params[:pen_name_id].blank?
      @pen_name = PenName.find_by_person_id_and_name_string_id(params[:person_id], params[:name_string_id])
    else
      @pen_name = PenName.find_by_id(params[:id])
      @pen_name ||= PenName.find_by_id(params[:pen_name_id])
    end
  end

end