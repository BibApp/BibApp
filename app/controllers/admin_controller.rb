class AdminController < ApplicationController
  #Only System Admins can access this controller's methods
  permit "admin of System"
  
  
  make_resourceful do
    build :all
  end
  
  #Find Works which are marked "Ready to Archive"
  def ready_to_archive
    @works = WorkArchiveState.ready_to_archive.works
  end
  
 
  # Deposit immediately via SWORD
  def deposit_via_sword
   
    #get our Work
    @work = Work.find(params[:work_id])
 
    #Generate a SWORD package and deposit it. 
    # Receive back a hash of deposit information
    @deposit = send_sword_package(@work)
    
    logger.debug("DEPOSIT HASH =" + @deposit.inspect)
    
    #Publisher.find_or_create_by_name(publisher_name)
    #Find ExternalSystem corresponding to SWORD Server
    system = ExternalSystem.find_by_name(@deposit[:server][:name])
    if system.nil? #if it doesn't exist by name, create it
      system = ExternalSystem.find_or_create_by_name_and_base_url(
                     :name      => @deposit[:server][:name],
                     :base_url  => @deposit[:server][:uri])
    end
    
    #Save the URI generated from our deposit
    ExternalSystemUri.find_or_create_by_work_id_and_external_system_id_and_uri(
                    :work_id => @work.id,
                    :external_system_id => system.id,
                    :uri => @deposit[:deposit_url])
   
    
    #Save the date deposited to Works table (this will also change the Archived State)
    @work.archived_at = DateTime.parse(@deposit[:updated])
    @work.save
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
    return SwordClient::Response.parse_post_response(response_doc)
  end
  
  
end
