class AdminController < ApplicationController
  #Only System Admins can access this controller's methods
  permit "admin of System"
  
  
  make_resourceful do
    build :all

  end

  def index
    @tab_name = params[:tab] || "works"
  end
  
  #Find Works which are marked "Ready to Archive"
  def ready_to_archive
    @works = Work.ready_to_archive
  end
  
 
  # Deposit immediately via SWORD
  def deposit_via_sword
   
    #get our Work
    @work = Work.find(params[:work_id])
 
    #Generate a SWORD package and deposit it. 
    # Receive back a hash of deposit information
    @deposit = send_sword_package(@work)
    
    logger.debug("DEPOSIT HASH =" + @deposit.inspect)
    
    #Find ExternalSystem corresponding to local Institutional Repository
    system = ExternalSystem.find_by_base_url($REPOSITORY_BASE_URL)
    #If not found by base URL,  try finding by name
    system = ExternalSystem.find_by_name($REPOSITORY_NAME) if system.nil?
    
    
    if system.nil? #if it doesn't exist , create it
      system = ExternalSystem.find_or_create_by_name_and_base_url(
                     :name      => $REPOSITORY_NAME,
                     :base_url  => $REPOSITORY_BASE_URL)
    end
    
    #Save the URI returned from our SWORD deposit to this repository
    ExternalSystemUri.find_or_create_by_work_id_and_external_system_id_and_uri(
                    :work_id => @work.id,
                    :external_system_id => system.id,
                    :uri => @deposit['id'])

    #@TODO - NOT all repositories return a full URI in the @deposit['id'].
    #  In fact, only DSpace seems to do this.  Whereas Fedora & Eprints return
    #  internal identifiers in this field.  Can we translate those internal IDs
    #  into URLs for Fedora/EPrints?
    
    #Save the date deposited to Works table (this will also change the Archived State)
    @work.archived_at = DateTime.parse(@deposit['updated'])
    @work.save
  end
  
  
  def duplicates
    
    # Default the filter to only show works marked as "duplicate"
    filter = [Work.solr_duplicate_filter]
    # Add any param filters
    filter << params[:fq] if params[:fq]
    filter = filter.compact
    filter.flatten!

    # Default SolrRuby params
    @query        = "*:*" # Lucene syntax for "find everything"
    @filter       = filter.clone
    @filter_no_strip = filter.clone
    @filter       = @filter.each{|f| f.strip!}
    @sort         = params[:sort] || "year"
    @sort         = "year" if @sort.empty?
    @page         = params[:page] || 0
    @facet_count  = params[:facet_count] || 50
    @rows         = params[:rows] || 10
    @export       = params[:export] || ""

    @q,@works,@facets = Index.fetch(@query, @filter, @sort, @page, @facet_count, @rows)
    t = true
  end

  def update_sherpa_data
  end

  def update_publishers_from_sherpa
    begin
      Publisher.update_sherpa_data
    rescue Exception => e
      respond_to do |format|
        flash[:notice] = "Error updating publisher data: #{e.message}"
        format.html {redirect_to url_for(:controller => :admin, :action => :update_sherpa_data)}
        format.xml  {head :error}
      end
    else
      respond_to do |format|
        flash[:notice] = "Update successful."
        format.html {redirect_to url_for(:controller => :admin, :action => :update_sherpa_data)}
        format.xml  {head :ok}
      end
    end
  end
  
  ######
  # Private methods
  ######
  private
  
  ##
  # Actually build and send the SWORD package for a given Work
  # 
  # Returns a parsed out hash of the response from SWORD Server
  ##
  def send_sword_package(work)
    require 'zip/zip'
    require 'zip/zipfilesystem'
    require 'sword_client'
    
    #Generating SWORD Package, which is a
    # single Zip file containing:
    #  - METS package (named 'mets.xml')  
    #  - all associated files (referenced by name in METS package)
 
    # Generate a Temp file, which we'll use to Zip everything up into
    # general concept borrowed from:
    # http://info.michael-simons.eu/2008/01/21/using-rubyzip-to-create-zip-files-on-the-fly/
    t = Tempfile.new("sword-deposit-file-#{work.id}.zip")
    
    # Give the path of the temp file to the zip outputstream, it won't try to open it as an archive.
    Zip::ZipOutputStream.open(t.path) do |zos|
      # add entry for our METS package
      zos.put_next_entry("mets.xml")
      # render our METS package for this Work
      zos.print render_to_string(:partial => "works/package.mets.haml", :locals => {:work => work, :filenames_only => true })
      
      #loop through attached files
      work.attachments.each do |att|
        #add entry with filename
        zos.put_next_entry(att.filename)
        
        #open file in appropriate mode
        if att.content_type.match('^text\/.*') #check if MIME Type begins with "text/"
          file=File.open(att.absolute_path) # open as normal (text-based format)
        else
           file=File.open(att.absolute_path, 'rb') # force opening in Binary file mode
        end 
        
        #add contents of file
        zos.print file.read
      end
    end
    # End of the block  automatically closes the temp file.

    # Download it to your browser, with correct mimetype
    # send_file t.path, :type => 'application/zip', :disposition => 'attachment', :filename => "sword.zip"
    
    # Post the temp file to our SWORD Server (configured in sword.yml)
    client = SwordClient.new
    response_doc = client.post_file t.path

    # The temp file will be deleted some time...
    t.close
    
    #parse out our response doc into a hash and return
    return SwordClient::Response.post_response_to_hash(response_doc)
  end
  
  
end
