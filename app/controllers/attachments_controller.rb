require 'sword_client'

class AttachmentsController < ApplicationController

  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy]

  make_resourceful do
    build :index, :show, :new, :edit

    #initialize variables used by 'new.html.haml'
    before :new do

      #load asset information
      load_asset

      if @asset.kind_of?(Person)
        @person = @asset
      end

      #only editors of this asset can attach files to it
      permit "editor of asset"

      #if 'type' unspecified, default to first type in list
      params[:type] ||= Attachment.types[0]

      # Default to Image for Person asset
      # @TODO: Is there a better way to default this?
      params[:type] = "Image" if @asset.kind_of?(Person)


      #initialize attachment subclass with any passed in attachment info
      @attachment = subklass_init(params[:type], params[:attachment])


      #SWORD Client is only applicable for ContentFile attachments
      if @attachment.kind_of?(ContentFile)
        #get SWORD information if SWORD is configured
        if SwordClient.configured?
          get_sword_info #gets License & Repository Name for View
        else
          flash[:error] = "SWORD does not seem to be configured in #{Rails.root}/config/sword.yml!<br/> Although uploading files will work, you won't be able to push them into your local repository."
        end
      end
    end

    before :edit do
      #load asset information
      load_asset
      if @asset.kind_of?(Person)
        @person = @asset
      end
    end

    before :index do
      #load asset information
      load_asset
    end

  end # end make_resourceful

  #Create one or more attachments
  #
  # Attachments are uploaded via a form with the
  # following features:
  # (1) Form must specify :multipart => true
  # (2) One or more file_field_tags named "file[]"
  # (3) Three hidden_field_tags:
  #      - "type" => Type of Attachment
  #      - "asset_id" => ID of asset this attachment is "attached" to
  #      - "asset_type" => Type of asset this attachment is "attached" to
  def create

    load_asset
    permit "editor of asset"
    attachment_count = 0

    if params[:file].nil?
      respond_to do |format|
        flash[:warning] = 'No file was uploaded.'
        format.html { redirect_to new_person_attachment_path(@asset.id) }
        format.xml { render :head => "ok" }
      end
      return
    end

    #initialize attachment(s) based on form info
    #(This allows for multiple uploads)
    params[:file].each do |f|
      #only upload if there's content to upload!
      if f and f.size > 0
        #initialize new attachment with uploaded file data
        @attachment = subklass_init(params[:type], f)
        #add attachment to asset
        if @asset.kind_of?(Work)
          #Works can have many files as attachments
          @asset.attachments << @attachment
        elsif @asset.kind_of?(Person)
          #Group or Person can only have one image attached
          @asset.image = @attachment
        end
        attachment_count += 1
      end
    end

    respond_to do |format|
      if @asset.save
        flash[:notice] = (attachment_count == 1) ? 'Attachment was successfully uploaded' :
            "#{attachment_count.to_s} attachments were successfully uploaded"
        if @asset.kind_of?(Person)
          format.html { redirect_to edit_person_attachment_path(@asset.id, @asset.image.id) }
          format.xml { head :created, :location => get_response_url(@asset) }
        else
          format.html { redirect_to get_response_url(@asset) }
          format.xml { head :created, :location => get_response_url(@asset) }
        end
      else
        format.html { render :action => "new" }
        format.xml { render :xml => @attachment.errors.to_xml }
      end
    end
  end

  def update
    @attachment = Attachment.find(params[:id])

    permit "editor of :asset", :asset => @attachment.asset

    if params[:attachment].blank?
      respond_to do |format|
        flash[:warning] = 'No file was uploaded.'
        if @attachment.asset.kind_of?(Person)
          format.html { redirect_to edit_person_attachment_path(@attachment.asset.id, @attachment.id) }
          format.xml { head :ok }
        else
          format.html { redirect_to get_response_url(@attachment.asset) }
          format.xml { head :ok }
        end
      end
      return
    end

    @attachment.attributes = params[:attachment]
    respond_to do |format|
      if @attachment.save
        flash[:notice] = 'Attachment was successfully uploaded'
        if @asset.kind_of?(Person)
          format.html { redirect_to edit_person_attachment_path(@attachment.asset.id, @attachment.id) }
          format.xml { head :created, :location => get_response_url(@attachment.asset) }
        else
          format.html { redirect_to get_response_url(@attachment.asset) }
          format.xml { head :created, :location => get_response_url(@attachment.asset) }
        end
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @attachment.errors.to_xml }
      end
    end
  end

  def destroy
    @attachment = Attachment.find(params[:id])
    asset = @attachment.asset

    #only editors of asset can delete attachments
    permit "editor of :asset", :asset => asset

    @attachment.destroy if @attachment

    respond_to do |format|
      if asset.save! #make sure asset's after_save callbacks are called
        flash[:notice] = 'Attachment was successfully deleted'

        if asset.kind_of?(Person)
          format.html { redirect_to new_person_attachment_path(asset.id) }
          format.xml { head :ok }
        else
          format.html { redirect_to get_response_url(asset) }
          format.xml { head :ok }
        end
      end
    end
  end


  # Pull down necessary information
  # from SWORD Server for the default collection
  def get_sword_info

    #initialize SWORD client based on SWORD config (sword.yml)
    sword_client = SwordClient.new

    #get our default collection info from SWORD service document
    # (this automatically requests the service doc as necessary)
    default_collection = sword_client.get_default_collection

    # @TODO, right now we are dependent on a default collection!
    if !default_collection.nil?
      #save license text for display in view
      @license = default_collection['collectionPolicy']

      #save repository name for display in view
      @repository_name = sword_client.get_repository_name
    end
  end

  # Adds more file upload boxes to the web form,
  # to allow for multi-uploads
  def add_upload_box
    form = params[:form]
    #Add new upload field dynamically using Javascript
    respond_to do |format|
      format.js { render :action => 'add_file_box', :locals => {:form => form} }
    end
  end


  ###
  # Private Methods
  ###
  private

  # Initializes a new attachment subclass, but doesn't create it in the database
  def subklass_init(klass_type, file)
    klass_type.sub!(" ", "") #remove spaces
    klass_type.gsub!(/[()]/, "") #remove any parens
    klass = klass_type.constantize #change into a class
    if klass.superclass != Attachment
      raise NameError.new("#{klass_type} is not a subclass of Attachment") and return
    end
    klass.new({:uploaded_data => file})
  end

  #Load the asset this attachment is attached to
  def load_asset
    if params[:work_id]
      @asset = Work.find(params[:work_id])
    elsif params[:person_id]
      @asset = Person.find(params[:person_id])
    end
  end

  #determine redirect URL based on asset type
  def get_response_url(asset)
    if asset.kind_of?(Work)
      #return to Work page
      return work_url(asset)
    elsif asset.kind_of?(Person)
      #return to Person page
      return person_url(asset)
    end
  end

end