class WorksController < ApplicationController
  
  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [ :new, :create, :edit, :update, :destroy ]
   
  before_filter :find_authorities, :only => [:new, :edit]

  # Find the @cart variable, used to display "add" or "remove" links for saved works
  before_filter :find_cart, :only => [:index, :show]

  make_resourceful do
    build :show, :new, :edit, :destroy
    
    publish :xml, :json, :yaml, :attributes => [
      :id, :type, :title_primary, :title_secondary, :title_tertiary,
      :year, :volume, :issue, :start_page, :end_page, :links, :tags, {
        :publication => [:id, :name]
        }, {
        :publisher => [:id, :name]
        }, {
        :name_strings => [:id, :name]
        }, {
        :people => [:id, :first_last]
        }
      ]
    
    #Add a response for METS!
    response_for :show do |format| 
      format.html  #loads show.html.haml (HTML needs to be first, so I.E. views it by default)
      format.mets  #loads show.mets.haml
    end

    #initialize variables used by 'new.html.haml'
    before :new do
      #Anyone with 'editor' role (anywhere) can add works
      permit "editor"
      
      #if 'type' unspecified, default to first type in list
      params[:type] ||= Work.types[0]

      #initialize work subclass with any passed in work info
      @work = subklass_init(params[:type], params[:work])
    end
    
    before :show do
      @recommendations = Index.recommendations(@current_object)
    end
    
    before :edit do
      #Anyone with 'editor' role on this work can edit it
      permit "editor on work"
    end
    
    before :destroy do
      #Anyone with 'admin' role on this work can destroy it
      permit "admin on work"
    end
  end # end make_resourceful

  def index
    @remote_ip = request.env["HTTP_X_FORWARDED_FOR"] 

    # Default SolrRuby params
    @query        = "*:*" # Lucene syntax for "find everything"
    @filter       = params[:fq] || ""
    @filter_no_strip = params[:fq] || ""
    @filter       = @filter.split("+>+").each{|f| f.strip!}
    @sort         = params[:sort] || "year"
    @sort         = "year" if @sort.empty?
    @page         = params[:page] || 0
    @facet_count  = params[:facet_count] || 50
    @rows         = params[:rows] || 10
    @export       = params[:export] || ""

    @q,@works,@facets = Index.fetch(@query, @filter, @sort, @page, @facet_count, @rows)

    #@TODO: This WILL need updating as we don't have *ALL* work info from Solr!
    # Process:
    # 1) Get AR objects (works) from Solr results
    # 2) Init the WorkExport class
    # 3) Pass the export variable and works to Citeproc for processing

    if @export && !@export.empty?
      works = Work.find(@works.collect{|c| c["pk_i"]}, :order => "publication_date desc")
      ce = WorkExport.new
      @works = ce.drive_csl(@export,works)
    end
    
    @view = params[:view] || "splash"
  end
  
  def create
    #Anyone with 'editor' role (anywhere) can add works
    permit "editor"

    # If we need to add a batch
    if params[:type] == "AddBatch"
    
      logger.debug("\n\n===ADDING BATCH WORKS===\n\n")
      unless params[:work][:works_file].nil? or params[:work][:works_file].kind_of?String
        #user uploaded a file of works
        successful = import_batch!(params[:work][:works_file])
      else 
        #user used cut & paste to add works
        successful = import_batch!(params[:work][:works])
      end
      
      
      respond_to do |format|
        if successful == 1
          flash[:notice] = "Batch creation completed successfully."
          format.html {redirect_to new_work_url}
          format.xml  {head :created, :location => work_url(@work)}
        elsif successful == 2
          flash[:unsuccessful] = "There was an unrecoverable error caused by the input!  Please contact your Administrator and let them know about this problem."
          format.html {redirect_to new_work_url}
          format.xml  {render :xml => @work.errors.to_xml}
        elsif successful == 3
          flash[:unsuccessful] = "Batch import successful, but some works were missing a required field"
          format.html {redirect_to new_work_url}
          format.xml  {render :xml => @work.errors.to_xml}
        else
          flash[:unsuccessful] = "The format of the file was unrecognized or unsupported.  Supported formats include: RIS, MedLine and Refworks XML"
          format.html {redirect_to new_work_url}
          format.xml  {render :xml => @work.errors.to_xml}        
        end
      end

    else
      logger.debug("\n\n===ADDING SINGLE WORK===\n\n")

      # Create the basic Work SubKlass
      @work = subklass_init(params[:type], params[:work])
    
    
      #Update work information based on inputs
      update_work_info
    
      # current user automatically gets 'admin' permissions on work
      # (only if he/she doesn't already have that permission)
      @work.accepts_role 'admin', current_user if !current_user.has_role?( 'admin', @work)
    
      respond_to do |format|
        if @work.save and Index.update_solr(@work)
          flash[:notice] = "Work was successfully created."
          format.html {redirect_to work_url(@work)}
          format.xml  {head :created, :location => work_url(@work)}
        else
          format.html {render :action => "new"}
          format.xml  {render :xml => @work.errors.to_xml}
        end
      end # If we are adding one
    end # If we need to add a batch
  end
  
  
  def update
    @work = Work.find(params[:id])
    
    #Anyone with 'editor' role on this work can edit it
    permit "editor on work"
    
    #First, update work attributes (ensures deduplication keys are updated)
    @work.attributes=params[:work]   

    #Then, update other work information
    update_work_info
   
    respond_to do |format|
      flash[:notice] = "Work was successfully updated."
      format.html {redirect_to work_url(@work)}
      format.xml  {head :ok}
    end
  end
  
  
  # Actually update all properties of this Work
  # This is called by both create() and update()
  def update_work_info
    ###
    # Setting WorkNameStrings
    ###

    #default to empty array of author strings
    params[:author_name_strings] ||= [] 
    params[:editor_name_strings] ||= [] 
            
    #Set Author NameStrings for this Work
    @author_name_strings = params[:author_name_strings]
    @editor_name_strings = params[:editor_name_strings]
    work_name_strings = Array.new
    @author_name_strings.each do |name|
      work_name_strings << {:name => name, :role => "Author"}
    end
    
    @editor_name_strings.each do |name|
      work_name_strings << {:name => name, :role => "Editor"}
    end
    
    @work.work_name_strings = work_name_strings 
      
    ###
    # Setting Keywords
    ###
    # Save keywords to instance variable @keywords,
    # in case any errors should occur in saving work
    @keywords = params[:keywords]
    @work.keyword_strings = @keywords
    
    ###
    # Setting Tags
    ###
    # Save tags to instance variable @tags,
    # in case any errors should occur in saving work    
    @tags = params[:tags]
    @work.tag_strings = @tags

    ###
    # Setting Publication Info, including Publisher
    ###
    issn_isbn = params[:issn_isbn]
    publication_info = Hash.new
    

    
    if params[:type] != 'BookWhole' && params[:type] != 'BookSection' && params[:type] != 'BookEdited'
      publication_info = {:name => params[:publication][:name], 
                          :issn_isbn => issn_isbn,
                          :publisher_name => params[:publisher][:name]}
    else
      publication_info = {:name => params[:work][:title_primary], 
                          :issn_isbn => issn_isbn,
                          :publisher_name => params[:publisher][:name]}
 
    end


    @work.publication_info = publication_info
    
    ###
    # Setting De-Duplication keys
    ###
    @work.issn_isbn_dupe_key = Work.set_issn_isbn_dupe_key(@work, work_name_strings, issn_isbn)
    @work.title_dupe_key = Work.set_title_dupe_key(@work)
    
  end
  
  
  # Load name strings list from Request params
  # and set for the current work.
  # Also sets the instance variable @author_name_strings,
  # in case any errors should occur in saving work
  def set_author_name_strings(work)
  	#default to empty array of author strings
    params[:author_name_strings] ||= []	
				    
    #Set NameStrings for this Work
    @author_name_strings = Array.new
    params[:author_name_strings].each do |add|
      name_string = NameString.find_or_initialize_by_name(add)
      @author_name_strings << {:name => name_string, :role => "Author"}
    end
    work.work_name_strings = @author_name_strings 	
   
 end
 
  # Load name strings list from Request params
  # and set for the current work.
  # Also sets the instance variable @editor_name_strings,
  # in case any errors should occur in saving work
  def set_editor_name_strings(work)
    #default to empty array of author strings
    params[:editor_name_strings] ||= [] 
           
    #Set NameStrings for this Work
    @editor_name_strings = Array.new
    params[:editor_name_strings].each do |add|
      name_string = NameString.find_or_initialize_by_name(add)
      @editor_name_strings << {:name => name_string, :role => "Editor"}
    end
    work.work_name_strings = @editor_name_strings   
   
  end
    	
  #Auto-Complete for entering Author NameStrings in Web-based Work entry
  def auto_complete_for_author_string
    auto_complete_for_name_string(params[:author][:string])
  end
  
  #Auto-Complete for entering Editor NameStrings in Web-based Work entry
  def auto_complete_for_editor_string
    auto_complete_for_name_string(params[:editor][:string])
  end 
  
  #Auto-Complete for entering NameStrings in Web-based Work entry
  #  This method provides users with a list of matching NameStrings
  #  already in BibApp.
  def auto_complete_for_name_string(name_string)
    name_string = name_string.downcase
  
    #search at beginning of name
    beginning_search = name_string + "%"
    #search at beginning of any other words in name
    word_search = "% " + name_string + "%"  
  
    name_strings = NameString.find(:all, 
      :conditions => [ "LOWER(name) LIKE ? OR LOWER(name) LIKE ?", beginning_search, word_search ], 
      :order => 'name ASC',
      :limit => 8)
      
    names = Array.new  
    name_strings.each do |obj|
      names << obj.name
    end
    
    render :partial => 'autocomplete_list', :locals => {:objects => names}
  end
  
  
  #Auto-Complete for entering Keywords in Web-based Work entry
  #  This method provides users with a list of matching Keywords
  #  already in BibApp.  This also include Tags.
  def auto_complete_for_keyword_name
   	keyword = params[:keyword][:name].downcase
	  
    #search at beginning of word
    beginning_search = keyword + "%"
    #search at beginning of any other words
    word_search = "% " + keyword + "%"	
	  
    #Search both keyworks and tags
    
    keywords = Keyword.find(:all, 
			  :conditions => [ "LOWER(name) LIKE ? OR LOWER(name) LIKE ?", beginning_search, word_search ], 
			  :order => 'name ASC',
			  :limit => 8)
        


    tags =  Tag.find(:all, 
        :conditions => [ "LOWER(name) LIKE ? OR LOWER(name) LIKE ?", beginning_search, word_search ], 
        :order => 'name ASC',
        :limit => 8)
    
    #Combine both lists
    keywordsandtags = Array.new
    keywords.each do |obj|
      keywordsandtags << obj.name
    end
    
    tags.each do |obj|
      keywordsandtags << obj.name
    end         
			
    render :partial => 'autocomplete_list', :locals => {:objects => keywordsandtags.uniq.sort.first(8) }
  end  
  
  
  #This is the same as for keywords, except this is used with tags
  def auto_complete_for_tag_name
    tag = params[:tag][:name].downcase
    
    
    #search at beginning of word
    beginning_search = tag + "%"
    #search at beginning of any other words
    word_search = "% " + tag + "%"  
    
    #Search both keyworks and tags
    
    keywords = Keyword.find(:all, 
        :conditions => [ "LOWER(name) LIKE ? OR LOWER(name) LIKE ?", beginning_search, word_search ], 
        :order => 'name ASC',
        :limit => 8)
        


    tags =  Tag.find(:all, 
        :conditions => [ "LOWER(name) LIKE ? OR LOWER(name) LIKE ?", beginning_search, word_search ], 
        :order => 'name ASC',
        :limit => 8)
    
    #Combine both lists
    keywordsandtags = Array.new
    keywords.each do |obj|
      keywordsandtags << obj.name
    end
    
    tags.each do |obj|
      keywordsandtags << obj.name
    end         
      
    render :partial => 'autocomplete_list', :locals => {:objects => keywordsandtags.uniq.sort.first(8) }
  end  
  
  #Auto-Complete for entering Publication Titles in Web-based Work entry
  #  This method provides users with a list of matching Publications
  #  already in BibApp.
  def auto_complete_for_publication_name
	  publication_name = params[:publication][:name].downcase
	  
	  #search at beginning of name
	  beginning_search = publication_name + "%"
	  #search at beginning of any other words in name
	  word_search = "% " + publication_name + "%"
	  
	  publications = Publication.find(:all, 
	  		  :conditions => [ "LOWER(name) LIKE ? OR LOWER(name) LIKE ?", beginning_search, word_search ], 
			  :order => 'name ASC',
			  :limit => 8)
			
	  render :partial => 'publication_autocomplete_list', :locals => {:publications => publications}
	end 
 
  #Auto-Complete for entering Publisher Name in Web-based Work entry
  #  This method provides users with a list of matching Publishers
  #  already in BibApp.
  def auto_complete_for_publisher_name
    publisher_name = params[:publisher][:name].downcase
    
    #search at beginning of name
    beginning_search = publisher_name + "%"
    #search at beginning of any other words in name
    word_search = "% " + publisher_name + "%"
    
    publishers = Publisher.find(:all, 
          :conditions => [ "LOWER(name) LIKE ? OR LOWER(name) LIKE ?", beginning_search, word_search ], 
        :order => 'name ASC',
        :limit => 8)
      
    render :partial => 'autocomplete_list', :locals => {:objects => publishers}
  end      
        
  #Adds a single item value to list of items in Web-based Work entry
  # This is used to add multiple values in form (e.g. multiple NameStrings, Keywords, etc)
  # Expects three parameters:
  # 	item_name - "Name" of type of item (e.g. "name_string", "keywords")
  #     item_value - value to add to item list
  #     clear_field - Name of form field to clear after processing is complete
  #
  # (E.g.) item_name=>"name_string", item_value=>"Donohue, Tim", clear_field=>"author_name"
  #	  Above example will add value "Donohue, Tim" to list of "author_string" values in form.
  #   Specifically, it would add a new <li> to the <ul> or <ol> with an ID of "author_string_list". 
  #   It then clears the "author_name" field (which is the textbox where the value was entered).
  #   End result example (doesn't include AJAX code created, but you get the idea):
  #   <input type="textbox" id="author_name" name="author_name" value=""/>
  #   <ul id='author_string_list'>
  #     <li id='Donohue, Timothy' class='list_item'>
  #       <input type="checkbox" id="name_string[]" name="name_string[]" value="Donohue, Tim"/> Donohue, Tim
  #     </li>
  #   </ul>
  def add_item_to_list
    @item_name = params[:item_name]
    @item_value = params[:item_value]
    @clear_field = params[:clear_field]

    #Add item value to list dynamically using Javascript
      respond_to do |format|
      format.js { render :action => :item_list }
    end
  end
	
  #Removes a single item value from list of items in Web-based Work entry
  # This is used to remove from multiple values in form (e.g. multiple authors, keywords, etc)
  # Expects two parameters:
  #   item_name - "Name" of type of item (e.g. "name_string", "keywords")
  #   item_value - value to add to item list  
  #
  # Essentially this does the opposite of 'add_item_to_list', and removes
  # an existing item.
  def remove_item_from_list
    @item_name = params[:item_name]
    @item_value = params[:item_value]
    @remove = true

    #remove item value from list dynamically using Javascript
    respond_to do |format|
      format.js { render :action => :item_list }
    end
  end
  
  def update_tags
    @work = Work.find(params[:id])
    ###
    # Setting Tags
    ###
    # Save tags to instance variable @tags,
    # in case any errors should occur in saving work    
    @tags = params[:tags]
    @work.tag_strings = @tags

    respond_to do |format|
      if @work.save and Index.update_solr(@work)
        flash[:notice] = "Work was successfully updated."
        format.html {redirect_to work_url(@work)}
        format.xml  {head :ok}
      else
        format.html {render :action => "edit"}
        format.xml  {render :xml => @work.errors.to_xml}
      end
    end
  end
  
  private
  
  def find_cart
    @cart = session[:cart] ||= Cart.new
  end
  
  # Batch import Works
  def import_batch!(data)    
    
    #The recorded error messages on works will be displayed as follows:
      #1. List of works (or junk data) which is inconsistent with the work format
      #2. The number of successfully parsed works
      #3. A list of works which parsed fine, but are missing a required field
    



    #Return 1 if successful with no errors
    #Return 2 if there was an unrecoverable error
    #Return 3 if the import was successful, but some works were missing a required field
    #Return 4 if the work format is not supported or there were no works to parse
    success = 1 
    
    begin 
      # Read the data
      str = data
      if data.respond_to? :read
        str = data.read
      elsif File.readable?(data)
        str = File.read(data)
      end
    
      # Init: Parser and Importer
      p = CitationParser.new
      i = CitationImporter.new

      begin
        #Attempt to parse the data
        pcites = p.parse(str)
        
      #Rescue any errors in parsing  
      rescue Exception => e
        #Log entire error backtrace
        logger.error("An error occurred during Citation Parsing: #{e.message}\n")
        logger.error("\nError Trace: #{e.backtrace.join("\n")}")
        
        #Return that there was an unrecoverable error
        return 2
      end
        
        
      #Check to make sure there were not errors while parsing the data.
      
      #No citations were parsed
      if pcites.nil? || pcites.empty?
        return 4
      end
      
      logger.debug("\n\nParsed Citations: #{pcites.size}\n\n")
    
      # Map Import hashes
      attr_hashes = i.citation_attribute_hashes(pcites)
      logger.debug "#{attr_hashes.size} Attr Hashes: #{attr_hashes.inspect}\n\n\n"
    
      #Make sure there is data in the Attribute Hash
      return 4 if attr_hashes.nil?
      
      
      all_cites = attr_hashes.map { |h|
       
        # Initialize the Work
        klass = h[:klass]
      
        # Are we working with a legit SubKlass?
        klass = klass.constantize
        if klass.superclass != Work
          raise NameError.new("#{klass_type} is not a subclass of Work") and return
        end
      
        work = klass.new
      
      
        ###
        # Setting WorkNameStrings
        ###
        work_name_strings = h[:work_name_strings]
        work.work_name_strings = work_name_strings
      
        ###
        # Setting Publication Info, including Publisher
        ###
        issn_isbn = h[:issn_isbn]
        publication_info = Hash.new
        publication_info = {:name => h[:publication], 
                                    :issn_isbn => issn_isbn,
                                    :publisher_name => h[:publisher]}

        work.publication_info = publication_info
    
        if h[:title_primary].nil? or h[:title_primary] == ""
          puts("\nThe following work does not have a title and cannot be imported!\n #{h}\n\n")
          puts("End Citation \n\n")
          success = 3
        else
      
    
        ###
        # Setting Keywords
        ###
        work.keyword_strings = h[:keywords]

        # Ensure publication_date is good
        if h[:publication_date].nil? or h[:publication_date].empty?
          h[:publication_date] = Date.new(1)
        end
      
        # Clean the abstract
        # @TODO we'll want to clean all data
        code = HTMLEntities.new
        h[:abstract] = code.encode(h[:abstract], :decimal)
      
        # Clean the hash of non-Work table data
        # Cleaning preps hash for AR insert
        h.delete(:klass)
        h.delete(:work_name_strings)
        h.delete(:publisher)
        h.delete(:publication)
        h.delete(:publication_place)
        h.delete(:issn_isbn)
        h.delete(:keywords)
        h.delete(:source)
        # @TODO add external_systems to work import
        h.delete(:external_id)



        #save remaining hash attributes
        work.attributes=h
        work.issn_isbn_dupe_key = Work.set_issn_isbn_dupe_key(work, work_name_strings, issn_isbn)
        work.title_dupe_key = Work.set_title_dupe_key(work)
        work.save_and_set_for_index
   
      
        # current user automatically gets 'admin' permissions on work
        # (only if he/she doesn't already have that role on the work)
        work.accepts_role 'admin', current_user if !current_user.has_role?( 'admin', work)
        end
      }
      Index.batch_index
      
    #This error occurs if the works were parsed, but some bad data
    #was entered which caused an error to occur when saving the data
    #to the database.
    rescue Exception => e
      puts("\nThere was an unrecoverable error on the batch import!!\n") 
      puts("\nUnderlying error: #{e.to_s}\n")
      puts("\nError Trace: #{e.backtrace.join("\n")}")
      
      success = 2
      
      return success
    end
   
    #At this point, some or all of the works were saved to the database successfully.
    return success
  end
  
  
  
  # Initializes a new work subclass, but doesn't create it in the database
  def subklass_init(klass_type, work)
    klass_type.sub!(" ", "") #remove spaces
    klass_type.gsub!(/[()]/, "") #remove any parens
    klass = klass_type.constantize #change into a class
    if klass.superclass != Work
      raise NameError.new("#{klass_type} is not a subclass of Work") and return
    end
    work = klass.new(work)
  end
  
  def find_authorities
    @publication_authorities = Publication.find(:all, :conditions => ["id = authority_id"], :order => "name")
    @publisher_authorities = Publisher.find(:all, :conditions => ["id = authority_id"], :order => "name")
  end
  
end