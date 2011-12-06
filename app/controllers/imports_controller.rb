class ImportsController < ApplicationController
  
  # Require user be logged in for *everything* 
  before_filter :login_required
  
  def index
    # List all imports
    params[:user_id] ||= current_user.id
    @imports = Import.paginate(:conditions => {:user_id => params[:user_id]},
        :page => params[:page], :order => 'updated_at DESC')

    # Only allow users to view their own imports, unless they are System editors
    @authorized = true
    if params[:user_id].to_i != current_user.id.to_i && !current_user.has_role?("editor", System)
      flash[:error] = t('common.imports.unauthorized')
      @authorized = false
    end
  end
  
  def new
    if params[:person_id]
      @person = Person.find_by_id(params[:person_id].split("-")[0])
    else
      @person = nil
    end
  end
  
  def create
    # Start by creating the Attachment
    @attachment = ImportFile.new({:uploaded_data => params[:import][:import_file]})
    @attachment.save
    
    # Init our Import
    @import = Import.new
    @import.user_id = params[:user_id] || current_user.id
    @import.person_id = params[:person_id]
    
    # Associate Attachment to Import
    @import.import_file = @attachment
    
    # Try saving the import
    if @import.save
      # Success!
      respond_to do |format|
        flash[:notice] = t('common.imports.flash_create_success')
        format.html { redirect_to user_imports_path }
      end
    else
      # Error!
      flash[:error] = t('common.imports.flash_create_failure')
      respond_to do |format|
        format.html { redirect_to :back }
      end
    end
  end
  
  # Generates a form which allows individuals to review the citations
  # that were just bulk loaded *before* they make it into the system.
  def show
    @import = Import.find_by_id(params[:id])
    
    if @import.person_id
      @person = Person.find_by_id(@import.person_id)
    else
      @person = nil
    end
    
    @page = params[:page] || 1
    @rows = params[:rows] || 10
    
    #load last batch from session
    @work_batch = @import.works_added
    @errors = @import.import_errors
   
    # Init duplicate works count
    @dupe_count = 0
      
    #As long as we have a batch of works to review, paginate them
    if @work_batch.present?
      
      #determine number of duplicates in batch
      @work_batch.each do |work_id|
        work = Work.find_by_id(work_id)
        @dupe_count += 1 if work and work.duplicate?
      end
      
      @works = Work.where("id in (?)", @work_batch).paginate(:page => @page, :per_page => @rows)

    end
    
    #Return path for any actions that take place on 'Review Batch' page
    @return_path = user_imports_path(current_user, :page=>@page, :rows=>@rows)
  end
  
  def update
    @import = Import.find(params[:id])
    if params[:decision]
      case params[:decision]
      when "accept"
        @import.accept!
      when "reject"
        @import.reject!
      end
    end
    
    # Try saving the import
    if @import.save
      # Success!
      respond_to do |format|
        if @import.state == "accepted"
          flash[:notice] = t('common.imports.flash_update_accepted')
        elsif @import.state == "rejected"
          flash[:notice] = t('common.imports.flash_update_rejected')
        end
        format.html { redirect_to user_imports_path() }
      end
    else
      # Error!
      flash[:error] = t('common.imports.flash_update_error')
      respond_to do |format|
        format.html { redirect_to :back }
      end
    end
  end
end
