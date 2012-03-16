require 'cmess/guess_encoding'
require 'will_paginate/array'
require 'set'
class WorksController < ApplicationController
  #require CMess to help guess encoding of uploaded text files

  #Require a user be logged in to create / update / destroy
  before_filter :login_required,
                :only => [:new, :create, :edit, :update, :destroy, :destroy_multiple,
                          :orphans]

  before_filter :find_authorities, :only => [:new, :edit]

  make_resourceful do
    build :show, :new, :edit, :destroy

    publish :xml, :json, :yaml, :only => :show, :attributes => [
        :id, :type, :title_primary, :title_secondary, :title_tertiary,
        :year, :volume, :issue, :start_page, :end_page, :links, :tags,
        {:publication => [:id, :name]}, {:publisher => [:id, :name]},
        {:name_strings => [:id, :name]}, {:people => [:id, :first_last]}]

    #Add a response for METS!
    response_for :show do |format|
      format.html #loads show.html.haml (HTML needs to be first, so I.E. views it by default)
      format.mets #loads show.mets.haml
      format.rdf
    end

    response_for :index do |format|
      format.html
      format.xml
      format.yaml
      format.json
      format.rdf
    end

    #initialize variables used by 'new.html.haml'
    before :new do

      #check if we are adding new works directly to a person
      person_from_person_id

      if @person
        #If adding to a person, must be an 'editor' of that person
        permit "editor on person"
      else
        #Default: anyone with 'editor' role (anywhere) can add works
        permit "editor"
      end

      #if 'type' unspecified, default to first type in list
      params[:klass] ||= Work.types[0]

      #initialize work subclass with any passed in work info
      @work = subklass_init(params[:klass], params[:work])

    end

    before :show do
      @recommendations = Index.recommendations(@current_object).collect { |r| r.first }
      # Specify text at end of HTML title tag
      @title = @current_object.title_primary
      true
    end

    before :edit do
      #Anyone with 'editor' role on this work can edit it
      permit "editor on Work"

      #Check if there was a path passed along to return to
      @return_path = params[:return_path]
    end

    before :destroy do
      #Anyone with 'admin' role on this work can destroy it
      permit "admin on Work"
    end

  end # end make_resourceful

  def index
    @title = Work.model_name.human_pl
    if params[:person_id]
      @current_object = Person.find_by_id(params[:person_id].split("-")[0])
      @person = @current_object
      search(params)
    elsif params[:group_id]
      @current_object = Group.find_by_id(params[:group_id].split("-")[0])
      @group = @current_object
      search(params)
    elsif params[:format] == "rdf"
      params[:rows] ||= 100
      search(params)
    else
      logger.debug("\n\n===Works: #{@current_object.inspect}")
      # Default BibApp search method - ApplicationController

      #Solr filter query for active people
      params[:fq] ||= []
      params[:fq] << "person_active:true" if Person.where(:active => true).count > 0
      search(params)
    end
  end

  def orphans
    permit "editor for Work"
    @title = t('common.works.orphans')
    @orphans = Work.orphans.paginate(:page => params[:page] || 1, :per_page => params[:per_page] || 20)
  end

  def orphans_delete
    permit "editor for Work"
    if params[:orphan_delete]
      Work.find(params[:orphan_delete][:orphan_id]).each do |w|
        w.destroy
      end
    end
    redirect_to orphans_works_url(:page => params[:page], :per_page => params[:per_page])
  end

  def change_type
    t = params[:type]
    work = Work.find(params[:id])

    # lazy mapping of all creator/contributor roles to top creator role
    authors = work.work_name_strings.collect { |wns| [:name => wns.name_string.name, :role => t.constantize.creator_role] }

    work.update_type_and_save(t) if t
    work.set_work_name_strings authors

    Index.update_solr(work)

    respond_to do |format|
      format.html { redirect_to edit_work_path(work.id) }
      format.xml { head :ok }
    end
  end

  # For paging make_resourceful publish
  def current_objects
    page = params[:page] || 1
    @current_object ||= current_model.order("created_at DESC").paginate(:page => page, :per_page => 10)
  end

  #Create a new Work or many new Works
  def create
    #check if we are adding new works directly to a person
    person_from_person_id

    if @person
      #If adding to a person, must be an 'editor' of that person
      permit "editor on person"
    else
      #Default: anyone with 'editor' role (anywhere) can add works
      permit "editor"
    end

    #Check if user hit cancel button
    if params['cancel']
      #just return back to 'new' page
      respond_to do |format|
        format.html { redirect_to new_work_url }
        format.xml { head :ok }
      end

    else #Only perform create if 'save' button was pressed

      logger.debug("\n\n===ADDING SINGLE WORK===\n\n")

      #Create attribute hash
      r_hash = create_attribute_hash

      @work = Work.create_from_hash(r_hash)

      if @work.errors.blank?
        ensure_admin(@work, current_user)
        #If this was submitted as an individual work for a specific person then
        #automatically verify the contributorship
        if @person
          c = Contributorship.for_person(@person.id).for_work(@work.id).first
          c.verify_contributorship if c
        end
        respond_to do |format|
          flash[:notice] = t('common.works.flash_create')
          format.html { redirect_to work_url(@work) }
          format.xml { head :created, :location => work_url(@work) }
        end
      else
        respond_to do |format|
          format.html { render 'new' }
          format.xml { render :xml => @work.errors.to_xml }
        end
      end
    end
  end

  def update

    @work = Work.find(params[:id])

    #Check if there was a path and page passed along to return to
    return_path = params[:return_path]

    #Check if user hit cancel button
    if params['cancel']
      # just return back from where we came
      respond_to do |format|
        unless return_path.nil?
          format.html { redirect_to return_path }
        else
          #default to returning to work page
          format.html { redirect_to work_url(@work) }
        end
        format.xml { head :ok }
      end

    else #Only perform update if 'save' button was pressed
         #Anyone with 'editor' role on this work can edit it
      permit "editor on work"

      #First, update work attributes (ensures deduplication keys are updated)
      @work.attributes = params[:work]

      # Create attribute hash from params
      r_hash = create_attribute_hash

      @work.update_from_hash(r_hash)
      if @work.errors.blank?
        ensure_admin(@work, current_user)
        respond_to do |format|
          flash[:notice] = t('common.works.flash_update')
          if return_path.nil?
            #default to returning to work page
            format.html { redirect_to work_path(@work) }
          else
            format.html { redirect_to return_path }
          end
          format.xml { head :ok }
        end
      else
        respond_to do |format|
          @return_path = params[:return_path]
          format.html { render 'edit' }
          format.xml { render :xml => @work.errors.to_xml }
        end
      end
    end
  end

  def destroy
    permit "admin"

    work = Work.find(params[:id])
    return_path = params[:return_path] || works_url

    full_success = true

    #Find all possible dupe candidates from Solr, if any
    dupe_candidates = Index.possible_unaccepted_duplicate_works(work)

    #if this is an unaccepted work, it will show up in the list, so remove it first
    dupe_candidates.delete(work)

    if dupe_candidates.empty?
      #Destroy the work
      work.destroy
    else
      #can't destroy an accepted work that has duplicates
      if !work.accepted?
        work.destroy
      else
        full_success = false
      end
    end


    respond_to do |format|
      if full_success
        flash[:notice] = t('common.works.flash_destroy_success')
        #forward back to path which was specified in params
        format.html { redirect_to return_path }
        format.xml { head :ok }
      else
        flash[:warning] = t('common.works.flash_destroy_has_duplicates')
        format.html { redirect_to edit_work_path(work.id) }
        format.xml { head :ok }
      end
    end
  end

  def destroy_multiple
    #Anyone who is minimally an admin (on anything in system) can delete works
    #(NOTE: User will actually have to be an 'admin' on all works in this batch,
    #       otherwise he/she will not be able to destroy *all* the works)
    permit "admin"

    work_ids = params[:work_id]
    return_path = params[:return_path]

    full_success = true

    if work_ids.present?
      #Destroy each work one by one, so we can be sure user has 'admin' rights on all
      work_ids.each do |work_id|
        work = Work.find_by_id(work_id)

        #One final check...only an admin on this work can destroy it
        if logged_in? && current_user.has_role?("admin", work)
          work.destroy
        else
          full_success = false
        end
      end
    end

    respond_to do |format|
      if full_success
        flash[:notice] = t('common.works.flash_destroy_multiple_successful')
      else
        flash[:warning] = t('common.works.flash_destroy_multiple_privileges')
      end
      #forward back to path which was specified in params
      format.html { redirect_to return_path }
      format.xml { head :ok }
    end
  end


  # Load name strings list from Request params
  # and set for the current work.
  # Also sets the instance variable @author_name_strings,
  # in case any errors should occur in saving work
  def set_author_name_strings(work)
    @author_name_strings = Array.new
    set_contributor_name_strings(work, @author_name_strings, :author_name_strings, 'Author')
  end

  # Load name strings list from Request params
  # and set for the current work.
  # Also sets the instance variable @editor_name_strings,
  # in case any errors should occur in saving work
  def set_editor_name_strings(work)
    @editor_name_strings = Array.new
    set_contributor_name_strings(work, @editor_name_strings, :editor_name_strings, 'Editor')
  end

  def set_contributor_name_strings(work, accumulator, parameter_key, role)
    params[parameter_key] ||= []
    params[parameter_key].each do |name|
      name_string = NameString.find_or_initialize_by_name(name)
      accumulator << {:name => name_string, :role => role}
    end
    work.set_work_name_strings(accumulator)
  end

  #render a set of works shared between two authors
  def shared
    @title = t('works.shared.title')
    @authors = Person.find(params[:people])
    #find works - not elegant, but the easiest way may be to find the ids for each author, intersect,
    #and then re-find based on the remaining ids. Since the first steps won't instantiate objects it shouldn't
    #actually be bad
    work_sets = @authors.collect {|a| a.works.to_set}
    first_set = work_sets.pop
    ids = work_sets.inject(first_set) {|intersection, set| intersection.intersection(set) }.to_a
    proper_prepare_pagination
    @works = Work.where(:id => ids).paginate(:page => @page, :per_page => @rows).order(proper_work_order_phrase(@sort, @order))
  end

  private

  # Initializes a new work subclass, but doesn't create it in the database
  def subklass_init(klass_type, work)
    klass_type.gsub!(" ", "") #remove spaces
    klass_type.gsub!("/", "") #remove slashes
    klass_type.gsub!(/[()]/, "") #remove any parens
    klass = klass_type.constantize #change into a class
    if klass.superclass != Work
      raise NameError.new("#{klass_type} is not a subclass of Work")
    end
    klass.new(work)
  end

  def find_authorities
    @publication_authorities = Publication.authorities.order_by_name
    @publisher_authorities = Publisher.authorities.order_by_name
  end

  def person_from_person_id
    if params[:person_id]
      @person = Person.find(params[:person_id].split("-")[0])
    end
  end

  # Create a hash of Work attributes
  # This is called by both create() and update()
  def create_attribute_hash

    attr_hash = Hash.new
    attr_hash[:klass] = params[:klass]

    attr_hash[:person_id] = params[:person_id]

    ###
    # Setting WorkNameStrings
    ###

    #default to empty array
    params[:authors] ||= []
    params[:contributors] ||= []
    params[:author_roles] ||= []
    params[:contributor_roles] ||= []

    #Set Author & Editor NameStrings for this Work
    @work_name_strings = Array.new
    @author_name_strings = Array.new
    @editor_name_strings = Array.new

    accumulate_names_and_roles(params[:authors], params[:author_roles],
                               [@author_name_strings, @work_name_strings])
    accumulate_names_and_roles(params[:contributors], params[:contributor_roles],
                               [@editor_name_strings, @work_name_strings])

    attr_hash[:work_name_strings] = @work_name_strings

    ###
    # Setting Keywords
    ###
    # Save keywords to instance variable @keywords,
    # in case any errors should occur in saving work
    @keywords = params[:keywords].split(';').collect { |kw| kw.squish } if params[:keywords].present?
    attr_hash[:keywords] = @keywords

    ###
    # Setting Tags
    ###
    # Save tags to instance variable @tags,
    # in case any errors should occur in saving work
    #@tags = params[:tags]
    #@work.set_tag_strings(@tags)

    ###
    # Setting Publication Info, including Publisher
    ###
    @publication = Publication.new
    @publisher = Publisher.new
    @publication.issn_isbn = params[:issn_isbn]

    # Sometimes there will be no publication, sometimes it will be blank,
    # sometimes it will have a value. If it's nil or blank we still want
    # to have the @publication[:name] hash in case we're sent back to
    # the 'new' page due to a save error.
    @publication.name = params[:publication][:name] rescue nil
    @publisher.name = params[:publisher][:name] rescue nil

    attr_hash[:issn_isbn] = @publication.issn_isbn
    attr_hash[:publication] = @publication.name
    attr_hash[:publisher] = @publisher.name

    params[:work].each do |key, val|
      attr_hash[key.to_sym] = val
    end

    return attr_hash.delete_if { |key, val| val.blank? }

  end

  #name_array and role_array are parallel arrays
  #whenever the stripped name is not blank add a hash to each accumulator
  #of the form :name => name, :role => role
  def accumulate_names_and_roles(name_array, role_array, accumulators)
    name_array.zip(role_array).each do |row|
      name, role = row
      name.strip!
      unless name.blank?
        accumulators.each do |acc|
          acc << {:name => name, :role => role}
        end
      end
    end
  end

  def name_search(name, klass, limit = 8)
    beginning_search = "#{name}%"
    word_search = "% #{name}%"
    klass.where("LOWER(name) LIKE ? OR LOWER(name) LIKE ?", beginning_search, word_search).order_by_name.limit(limit)
  end

  def ensure_admin(work, user)
    work.accepts_role('admin', user) unless user.has_role?('admin', work)
  end

end
