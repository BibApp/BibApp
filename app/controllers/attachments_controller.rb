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
        @asset = object_find(params[:asset_type], params[:asset_id])
      end
    end
    
    #initialize variables used by 'edit.html.haml'
    before :edit do  
      #if 'type' unspecified, default to first type in list
      params[:type] ||= Attachment.types[0]
      
      @attachment = object_find(params[:type], params[:id])
      
      if params[:asset_type] and params[:asset_id]
        #initialize asset this attachment is being added to
        @asset = object_find(params[:asset_type], params[:asset_id])
      end
    end
   
  end # end make_resourceful  


  def create
    #initialize attachment based on form info
    @attachment = subklass_init(params[:type], params[:attachment])
    
    if params[:asset_type] and params[:asset_id]
        #initialize asset this attachment is being added to
        @asset = object_find(params[:asset_type], params[:asset_id])
        #add attachment to asset
        @attachment.asset = @asset unless @asset.nil?
    end
    
    respond_to do |format|
      if @attachment.save
        flash[:notice] = 'Attachment was successfully uploaded'
        format.html {redirect_to attachment_url(@attachment)}
        format.xml  {head :created, :location => attachment_url(@attachment)}    
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
    
    #if params[:asset_type] and params[:asset_id]
        #initialize asset this attachment is being added to
    #    @asset = object_find(params[:asset_type], params[:asset_id])
        #add attachment to asset
    #    @attachment.asset = @asset unless @asset.nil?
    #end
    
    respond_to do |format|
      if @attachment.save
        flash[:notice] = 'Attachment was successfully uploaded'
        format.html {redirect_to attachment_url(@attachment)}
        format.xml  {head :created, :location => attachment_url(@attachment)}    
      else
        format.html {render :action => "new"}
        format.xml  {render :xml => @attachment.errors.to_xml}
      end
    end
  end
  
  def destroy
    @attachment = Attachment.find(params[:id])
    asset = @attachment.asset
    @attachment.destroy if @attachment
    
    respond_to do |format|
      # @TODO Is there a better way to redirect back to appropriate asset type?
      if asset.kind_of?(Citation)
        flash[:notice] = 'Attachment was successfully deleted'
        format.html { redirect_to citation_url(asset) }
      end
      format.xml {head :ok }
    end
  end

  ###
  # Private Methods
  ###
  private

    # Initializes a new attachment subclass, but doesn't create it in the database
    def subklass_init(klass_type, attachment)
      klass_type.sub!(" ", "") #remove spaces
      klass_type.gsub!(/[()]/, "") #remove any parens
      klass = klass_type.constantize #change into a class
      if klass.superclass != Attachment
        raise NameError.new("#{klass_type} is not a subclass of Attachment") and return
      end
      attachment = klass.new(attachment)
    end
  
    # Initializes a new object, based on information provided
    def object_find(obj_type, obj_id)
      obj_type.sub!(" ", "") #remove spaces
      obj_type.gsub!(/[()]/, "") #remove any parens
      obj_class = obj_type.constantize #change into a class
      
      obj = obj_class.find(obj_id)
    end
  
end  