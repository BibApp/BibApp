class AdminController < ApplicationController
  
  make_resourceful do
    build :all
  end
  
  #Find citations which are marked "Ready to Archive"
  def ready_to_archive
    #@TODO: right now just listing 10 citations...this should be
    # more of a faceted view that allows you to find citations to archive next
    #@citations = Citation.find(:all, 
    #  :conditions => ["citation_archive_state_id = ? and citation_state_id = ?", 2, 3], 
    #  :limit => 10)
    
    @citations = CitationArchiveState.ready_to_archive.citations
  end
  
 
  # Deposit immediately via SWORD
  def deposit_via_sword
   
    #get our Citation
    @citation = Citation.find(params[:citation_id])
 
    #Generate a SWORD package and deposit it. 
    # Receive back a hash of deposit information
    @deposit = send_sword_package(@citation)
    
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
    ExternalSystemUri.find_or_create_by_citation_id_and_external_system_id_and_uri(
                    :citation_id => @citation.id,
                    :external_system_id => system.id,
                    :uri => @deposit[:deposit_url])
   
    
    #Save the date deposited to Citations table (this will also change the Archived State)
    @citation.archived_at = DateTime.parse(@deposit[:updated])
    @citation.save
  end
  
  
  ######
  # Private methods
  ######
  private
  
  ##
  # Actually build and send the SWORD package for a given Citation
  # 
  # Returns a parsed out hash of the response from SWORD Server
  ##
  def send_sword_package(citation)
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
    t = Tempfile.new("sword-deposit-file-#{citation.id}.zip")
    
    # Give the path of the temp file to the zip outputstream, it won't try to open it as an archive.
    Zip::ZipOutputStream.open(t.path) do |zos|
      # add entry for our METS package
      zos.put_next_entry("mets.xml")
      # render our METS package for this citation
      zos.print render_to_string(:partial => "citations/package.mets.haml", :locals => {:citation => citation, :filenames_only => true })
      
      #loop through attached files
      citation.attachments.each do |att|
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
