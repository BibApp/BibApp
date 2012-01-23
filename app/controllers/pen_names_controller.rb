require 'database_methods'

class PenNamesController < ApplicationController

  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [:new, :create, :destroy]

  before_filter :find_pen_name, :only => [:destroy]
  before_filter :find_person, :only => [:create, :create_name_string, :new, :destroy]
  before_filter :find_name_string, :only => [:create, :create_name_string, :destroy]
  before_filter :ajax_setup, :only => [:ajax_add, :ajax_destroy]

  make_resourceful do
    build :index, :show, :new, :update

    before :new do
      #only 'editor' of person can assign a pen name
      permit "editor of Person"

      @suggestions = NameString.name_like(@person.last_name).order_by_name
      @title = "#{@person.display_name}: #{PenName.model_name.human_pl}"

    end

    before :update do
      #only 'editor' of person can assign a pen name
      permit "editor of Person"
    end
  end


  def create
    #only 'editor' of person can assign a pen name
    permit "editor of Person"

    if params[:reload]
      @reload = true
    end

    @person.name_strings << @name_string
    respond_to do |format|
      format.html { redirect_to new_pen_name_path(:person_id => @person.id) }
    end
  end

  def create_name_string
    #only 'editor' of person can assign a pen name
    permit "editor of Person"

    name = params[:name_string][:name]
    machine_name = name.mb_chars.gsub(/[\W]+/, " ").strip.downcase

    @name_string = NameString.find_or_create_by_machine_name(machine_name)
    @name_string.name = name
    @name_string.save

    @person.name_strings << @name_string unless @person.name_strings.include?(@name_string)
    respond_to do |format|
      format.html do
        if request.xhr?
          render :partial => 'current_namestrings', :layout => false
        else
          redirect_to new_pen_name_path(:person_id => @person.id)
        end
      end
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
      format.html { redirect_to new_pen_name_path(:person_id => @person.id) }
    end
  end

  def ajax_add
    PenName.find_or_create_by_person_id_and_name_string_id(:person_id => @person.id, :name_string_id => @name_string.id)
    render :partial => 'current_namestrings', :layout => false
  end

  def ajax_destroy
    PenName.find_by_person_id_and_name_string_id(@person.id, @name_string.id).destroy
    render :partial => 'current_namestrings', :layout => false
  end

  def live_search_for_name_strings
    @phrase = params[:q]
    @person = Person.find(params[:person_id])

    @results = like_search(@phrase, @person.last_name).order_by_name

    @number_match = @results.length
    @results = @results - @person.name_strings

    respond_to do |format|
      format.html do
        if request.xhr?
          if @results.size < 1
            render :text => t('pen_names.name_string_filter.no_results_html', :phrase => @phrase)
          else
            render :partial => "name_string", :collection => @results, :locals => {:person => @person, :selected => false}, :layout => false
          end
        else
          redirect_to new_pen_name_path(:person_id => @person.id)
        end
      end
    end
  end

  private

  def ajax_setup
    @person = Person.find params[:person_id]
    @name_string = NameString.find params[:name_string_id].split('_').last
    permit 'editor of :person', :person => @person
  end

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

  def wildcard_search(string)
    "%#{string}%"
  end

  def like_search(*strings)
    like = DatabaseMethods.case_insensitive_like_operator
    query = (["name #{like} ?"] * strings.count).join(' OR ')
    params = strings.collect { |string| wildcard_search(string) }
    NameString.where(query, *params)
  end

end