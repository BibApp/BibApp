class WorksController < ApplicationController
  
  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [ :new, :create, :edit, :update, :destroy, :destroy_multiple ]
   
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
      
      #check if there was a batch created previously
      # (if so, we'll provide a link to review that batch)
      @last_batch = find_last_batch
    end
    
    before :show do
      @recommendations = Index.recommendations(@current_object)
      # Specify text at end of HTML <title> tag
      @title=@current_object.title_primary
    end
    
    before :edit do
      #Anyone with 'editor' role on this work can edit it
      permit "editor on work"
      
      #Check if there was a path passed along to return to
      @return_path = params[:return_path]
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
      unrecoverable_error = false
      begin
        unless params[:work][:works_file].nil? or params[:work][:works_file].kind_of?String
          #user uploaded a file of works
          @works_batch, @batch_errors = import_batch!(params[:work][:works_file])
        else 
          #user used cut & paste to add works
          @works_batch, @batch_errors = import_batch!(params[:work][:works])
        end
      rescue Exception => e
        logger.error("An unrecoverable error occurred during Batch Import: #{e.message}\n")
        logger.error("\nError Trace: #{e.backtrace.join("\n")}")
        #We just display an "unrecoverable error" message for now
        unrecoverable_error = true
      end
      
      respond_to do |format|
        if unrecoverable_error
          flash[:error] = "There was an unrecoverable error caused by the input!  Please contact the Administrators and let them know about this problem."
          format.html {redirect_to new_work_url}
          format.xml  {render :xml => @works_batch.errors.to_xml}
        elsif !@batch_errors.nil? and !@batch_errors.empty?
          flash[:warning] = "Batch creation was successful for some works.  However, we encountered the following problems with other works:<br/>#{@batch_errors.join('<br/>')}"
          format.html {redirect_to review_batch_works_url}
          format.xml  {render :xml => @works_batch.errors.to_xml}
        elsif !@works_batch.nil? and !@works_batch.empty?
          flash[:notice] = "Batch creation completed successfully."
          format.html {redirect_to review_batch_works_url}
          format.xml  {head :created}
        else #otherwise, we ended up with nothing imported!
          flash[:warning] = "The format of the input was unrecognized or unsupported.  Supported formats include: RIS, MedLine and Refworks XML"
          format.html {redirect_to new_work_url}
          format.xml  {render :xml => @works_batch.errors.to_xml}        
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
  
  # Generates a form which allows individuals to review the citations
  # that were just bulk loaded *before* they make it into the system.
  def review_batch
    @page = params[:page] || 1
    @rows = params[:rows] || 10
    
    #load last batch from session
    @work_batch = find_last_batch
   
    @dupe_count = 0
      
    #As long as we have a batch of works to review, paginate them
    if !@work_batch.nil? and !@work_batch.empty?
      
      #determine number of duplicates in batch
      @work_batch.each do |work_id|
        work = Work.find(work_id)
        @dupe_count+=1 if !work.nil? and work.duplicate?
      end
      
      @works = Work.paginate(
        :page => @page, 
        :per_page => @rows,
        :conditions => ["id in (?)", @work_batch]
      )
    end
    
    #Return path for any actions that take place on 'Review Batch' page
    @return_path = review_batch_works_path(:page=>@page, :rows=>@rows)
    
  end
  
  
  def update
    @work = Work.find(params[:id])
    #Check if there was a path and page passed along to return to
    return_path = params[:return_path]
    
    #Anyone with 'editor' role on this work can edit it
    permit "editor on work"
    
    #First, update work attributes (ensures deduplication keys are updated)
    @work.attributes=params[:work]   

    #Then, update other work information
    update_work_info
   
    respond_to do |format|
      flash[:notice] = "Work was successfully updated."
      unless return_path.nil?
        format.html {redirect_to return_path}
      else
        #default to returning to work page
        format.html {redirect_to work_url(@work)}
      end
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
  
  
  def destroy_multiple    
    #Anyone who is minimally an admin (on anything in system) can delete works
    #(NOTE: User will actually have to be an 'admin' on all works in this batch, 
    #       otherwise he/she will not be able to destroy *all* the works)
    permit "admin"

    work_ids = params[:work_id]
    return_path = params[:return_path]
    
    full_success = true
    
    unless work_ids.nil? or work_ids.empty?
      #Destroy each work one by one, so we can be sure user has 'admin' rights on all
      work_ids.each do |work_id|
        work = Work.find_by_id(work_id)

        #One final check...only an admin on this work can destroy it
        if logged_in? && current_user.has_role?("admin", work)
          work.destroy
        else
          full_success = false
        end
      end
    end
    
    respond_to do |format|
      if full_success
        flash[:notice] = "Works were successfully deleted."
      else
        flash[:warning] = "One or more works could not be deleted, as you have insufficient privileges"
      end
      #forward back to path which was specified in params
      format.html {redirect_to return_path }
      format.xml  {head :ok}
    end
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
    
    render :partial => 'works/forms/fields/autocomplete_list', :locals => {:objects => names}
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
			
    render :partial => 'works/forms/fields/autocomplete_list', :locals => {:objects => keywordsandtags.uniq.sort.first(8) }
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
      
    render :partial => 'works/forms/fields/autocomplete_list', :locals => {:objects => keywordsandtags.uniq.sort.first(8) }
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

    render :partial => 'works/forms/fields/publication_autocomplete_list', :locals => {:publications => publications}
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
      
    render :partial => 'works/forms/fields/autocomplete_list', :locals => {:objects => publishers}
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
    
    #default errors to none
    errors = Array.new
    
    # (1) Read the data
    begin 
      str = data
      if data.respond_to? :read
        str = data.read
      elsif File.readable?(data)
        str = File.read(data)
      end
    rescue Exception =>e
       #Log entire error backtrace
      logger.error("An error occurred reading the input data: #{e.message}\n")
      logger.error("\nError Trace: #{e.backtrace.join("\n")}")
      #re-raise this exception to create()
      raise
    end
    
    # Init: Parser and Importer
    p = CitationParser.new
    i = CitationImporter.new

    # (2) Parse the data using CitationParser plugin
    begin
      #Attempt to parse the data
      pcites = p.parse(str)

    #Rescue any errors in parsing  
    rescue Exception => e
      #Log entire error backtrace
      logger.error("An error occurred during Citation Parsing: #{e.message}\n")
      logger.error("\nError Trace: #{e.backtrace.join("\n")}")

      #re-raise this exception to create()
      raise
    end
        
        
    #Check to make sure there were not errors while parsing the data.

    #No citations were parsed
    if pcites.nil? || pcites.empty?
      return nil
    end

    logger.debug("\n\nParsed Citations: #{pcites.inspect}\n\n")

    # (3) Import the data using CitationImporter Plugin
    begin
      # Map Import hashes
      attr_hashes = i.citation_attribute_hashes(pcites)
      #logger.debug "#{attr_hashes.size} Attr Hashes: #{attr_hashes.inspect}\n\n\n"

      #Make sure there is data in the Attribute Hash
      return nil if attr_hashes.nil?
      
     
      #initialize an array of all the works we create in this batch
      works_added = init_last_batch 
      
      # Now, actually *create* these works in database
      attr_hashes.map { |h|
       
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
    
        # Very minimal validation -- just check that we have a title
        if h[:title_primary].nil? or h[:title_primary] == ""
          errors << "We couldn't find a title for at least one work...you may want to verify everything imported properly!"
          
          logger.warn("The following work did not have a title and could not be imported!\n #{h}\n\n")
          logger.warn("End Work \n\n")
        else
     
          ###
          # Setting Keywords
          ###
          work.keyword_strings = h[:keywords]

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
        
          #add to batch of works created
          works_added << work.id
        end #end if no title
      }
      #index everything in Solr
      Index.batch_index
      
    #This error occurs if the works were parsed, but some bad data
    #was entered which caused an error to occur when saving the data
    #to the database.
    rescue Exception => e
      #remove anything already added to the database (i.e. rollback ALL changes)
      unless works_added.nil?
        works_added.each do |work_id|
          work = Work.find(work_id)
          work.destroy unless work.nil?     
        end
        #re-initialize batch in order to clear it from session
        works_added = init_last_batch 
      end
      #reraise the error to create(), which will make sure it is logged
      raise
    end
   
    #At this point, some or all of the works were saved to the database successfully.
    return works_added, errors
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
  
  # Initialize information about the last batch of works
  # that was added during this current user's session
  def init_last_batch 
    last_batch = find_last_batch
    
    #clear last batch if not empty
    last_batch.clear unless last_batch.empty?
    
    #return cleared batch
    return last_batch
  end
  
  # Find the last batch of works that was added during
  # this current user's session.  Only work_ids are stored.
  def find_last_batch
    session[:works_batch] ||= Array.new
    
    # Quick cleanup of batch...remove any items which have been deleted
    session[:works_batch].delete_if{|work_id| !Work.exists?(work_id)}
  end
  
end