require 'sword2ruby'
require 'nokogiri'

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
        params[:type] = "Image"
      end

      #only editors of this asset can attach files to it
      permit "editor of asset"

      #if 'type' unspecified, default to first type in list
      params[:type] ||= Attachment.types[0]

      #initialize attachment subclass with any passed in attachment info
      @attachment = subklass_init(params[:type], params[:attachment])


      #SWORD Client is only applicable for ContentFile attachments
      if @attachment.kind_of?(ContentFile)
        #get SWORD information if SWORD is configured
        if Sword2Client.configured?
          get_sword_info #gets License & Repository Name for View
        else
          flash[:error] = t('common.attachments.flash_new_error', :rails_root => Rails.root.to_s)
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
        flash[:warning] = t('common.attachments.flash_create_warning')
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
        flash[:notice] = t('common.attachments.flash_create_notice', :count => attachment_count)
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

    if params[:file].blank?
      respond_to do |format|
        flash[:warning] = t('common.attachments.flash_update_warning')
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

    respond_to do |format|
      @attachment.uploaded_data = params[:file].first
      if @attachment.save
        flash[:notice] = t('common.attachments.flash_update_notice')
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
        flash[:notice] = t('common.attachments.flash_delete_notice')

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

    #initialize SWORD client based on SWORD config (sword.yml)\
    #TODO note - this is currently an abuse to use Sword2Client to deal with a v1.3 repository
    sword_client = Sword2Client.new

    service_doc = sword_client.repo.servicedoc
    service_doc_xml = Nokogiri::XML::Document.parse(service_doc)
    default_collection = service_doc_xml.at_xpath("//app:collection[@href='#{sword_client.config['default_collection_url']}']", service_doc_xml.namespaces)

    # @TODO, right now we are dependent on a default collection!
    if default_collection
      #save license text for display in view
      @license = default_collection.at_xpath("//sword:collectionPolicy", service_doc_xml.namespaces).text

      #save repository name for display in view
      @repository_name = service_doc_xml.at_xpath("//atom:title", service_doc_xml.namespaces).text
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
      raise NameError.new("#{klass_type} is not a subclass of Attachment")
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

  helper_method :get_response_url

end