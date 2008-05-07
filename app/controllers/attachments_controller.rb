class AttachmentsController < ApplicationController
  
  make_resourceful do
    build :index, :show, :new, :edit
    
    #initialize variables used by 'new.html.haml'
    before :new do  
      #if 'type' unspecified, default to first type in list
      params[:type] ||= Attachment.types[0]
      
      #initialize attachment subclass with any passed in attachment info
      @attachment = subklass_init(params[:type], params[:attachment])
      
      if params[:asset_type] and params[:asset_id]
        #initialize asset this attachment is being added to
        @asset = asset_find(params[:asset_type], params[:asset_id])
      end
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
    
    #initialize asset this attachment is being added to
    @asset = asset_find(params[:asset_type], params[:asset_id]) if params[:asset_type] and params[:asset_id]
    
    attachment_count=0
    
    #initialize attachment(s) based on form info
    #(This allows for multiple uploads)
    unless params[:file].nil?
      params[:file].each do |f|
        if !f.nil? and f.size>0 #only upload if there's content to upload!
          #initialize new attachment with uploaded file data
          @attachment = subklass_init(params[:type], f)
          #add attachment to asset
          if @asset.kind_of?(Citation)
            #Citations can have many files as attachments
            @asset.attachments << @attachment
          elsif @asset.kind_of?(Person) or @asset.kind_of?(Group)
            #Group or Person can only have one image attached
            @asset.image = @attachment
          end
          attachment_count+=1
        end
      end
    end
    
    respond_to do |format|
      if @asset.save
        
        if attachment_count==1
          flash[:notice] = 'Attachment was successfully uploaded'
        else
          flash[:notice] = attachment_count.to_s + ' attachments were successfully uploaded'
        end
        
        format.html {redirect_to get_response_url(@asset)}
        format.xml  {head :created, :location => get_response_url(@asset)}
      else
        format.html {render :action => "new"}
        format.xml  {render :xml => @attachment.errors.to_xml}
      end
    end
  end
  
  def update
    #load attachment based on form info
    @attachment = Attachment.find(params[:id])
    
    @attachment.attributes=params[:attachment]
    
    respond_to do |format|
      if @attachment.save
        flash[:notice] = 'Attachment was successfully uploaded'
        format.html {redirect_to get_response_url(@attachment.asset)}
        format.xml  {head :created, :location => get_response_url(@attachment.asset)}    
      else
        format.html {render :action => "edit"}
        format.xml  {render :xml => @attachment.errors.to_xml}
      end
    end
  end
  
  def destroy
    @attachment = Attachment.find(params[:id])
    asset = @attachment.asset
    @attachment.destroy if @attachment
    
    respond_to do |format|
      flash[:notice] = 'Attachment was successfully deleted'
      format.html {redirect_to get_response_url(asset)}
      format.xml  {head :ok }
    end
  end

  # Adds more file upload boxes to the web form,
  # to allow for multi-uploads
  def add_upload_box
    form = params[:form]
    #Add new upload field dynamically using Javascript
    respond_to do |format|
      format.js {  render :action => 'add_file_box', :locals => {:form => form} }
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
      attachment = klass.new({:uploaded_data => file})
    end
  
    # Finds an asset, based on information provided
    def asset_find(asset_type, asset_id)
      asset_type.sub!(" ", "") #remove spaces
      asset_type.gsub!(/[()]/, "") #remove any parens
      asset_class = asset_type.constantize #change into a class
      
      asset = asset_class.find(asset_id)
    end
  
    #determine redirect URL based on asset type
    def get_response_url(asset)
      if asset.kind_of?(Citation)
        #return to Citation page
        return citation_url(asset)
      elsif asset.kind_of?(Person)
        #return to Person page
        return person_url(asset)
      elsif asset.kind_of?(Group)
        #return to Group page
        return group_url(asset)
      end
    end
  
end  