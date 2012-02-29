require 'sword2ruby'
require 'nokogiri'
require 'tempfile'
require 'zip/zip_output_stream'

class Sword_1_3_Adapter

  def self.configured?
    Sword2Client.configured?
  end

  def self.repository_information
    client = Sword2Client.new
    service_doc = Nokogiri::XML::Document.parse(client.repo.servicedoc)
    default_collection_url = client.config['default_collection_url']
    default_collection = service_doc.at_xpath("//app:collection[@href='#{default_collection_url}']", service_doc.namespaces)
    HashWithIndifferentAccess.new.tap do |h|
      if default_collection
        h[:license] = default_collection.at_xpath("//sword:collectionPolicy", service_doc.namespaces).text
        h[:repository_name] = default_collection.at_xpath("//atom:title", service_doc.namespaces).text
      end
    end
  end

  def self.send_sword_package(work, work_mets)
    with_mets_package(work, work_mets) do |mets_file|
      response_xml = nil
      # Download it to your browser, with correct mimetype
      # send_file t.path, :type => 'application/zip', :disposition => 'attachment', :filename => "sword.zip"

      # Post the temp file to our SWORD Server (configured in sword.yml)
      #note that this is a way to abuse Sword2Client to send to a Sword 1.3 server
      client = Sword2Client.new
      begin
        client.execute("post", "collection", client.config['default_collection_url'], mets_file.path, {},
                                 {'Content-Type' => 'application/zip', 'X-Verbose' => 'true', 'X-No-Op' => 'false',
                                  'Content-Disposition' => "filename=#{File.basename(mets_file.path)}",
                                  'X-Packaging' => 'http://purl.org/net/sword-types/METSDSpaceSIP'})
        response_xml = client.depositreceipt.source
      rescue SwordDepositReceiptParseException => e
        response_xml = e.source_xml
      end
      #parse out our response doc into a hash and return
      return parse_sword_return_xml_to_hash(response_xml)
    end
  end

  protected

  #create a tempfile with the mets package and yield it
  def self.with_mets_package(work, work_mets)
    #Generating SWORD Package, which is a
    # single Zip file containing:
    #  - METS package (named 'mets.xml')
    #  - all associated files (referenced by name in METS package)
    Tempfile.open("sword-deposit-file-#{work.id}.zip") do |tempfile|

      # Give the path of the temp file to the zip outputstream, it won't try to open it as an archive.
      Zip::ZipOutputStream.open(tempfile.path) do |zip_stream|
        # add entry for our METS package
        zip_stream.put_next_entry("mets.xml")
        # render our METS package for this Work
        zip_stream.print work_mets

        #loop through attached files
        work.attachments.each do |att|
          #add entry with filename
          zip_stream.put_next_entry(att.data_file_name)

          #open file in appropriate mode
          if att.content_type.match('^text\/.*') #check if MIME Type begins with "text/"
            file=File.open(att.absolute_path) # open as normal (text-based format)
          else
            file=File.open(att.absolute_path, 'rb') # force opening in Binary file mode
          end

          #add contents of file
          zip_stream.print file.read
          file.close
        end
      end
      yield tempfile
    end
  end

  def self.parse_sword_return_xml_to_hash(return_xml)
    doc = Nokogiri::XML::Document.parse(return_xml)
    HashWithIndifferentAccess.new.tap do |h|
      {:atom => [:id, :updated, :title], :sword => [:treatment]}.each do |namespace, fields|
        fields.each do |field|
          h[field] = doc.at_xpath("//#{namespace}:#{field}", doc.namespaces).text
        end
      end
    end
  end

end
