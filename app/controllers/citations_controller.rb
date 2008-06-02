class CitationsController < ApplicationController
  before_filter :find_authorities, :only => [:new, :edit]

  make_resourceful do
    build :index, :show, :new, :edit, :destroy
    
    publish :xml, :json, :yaml, :attributes => [
      :id, :type, :title_primary, :title_secondary, :title_tertiary,
      :year, :volume, :issue, :start_page, :end_page, :links, {
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
      format.mets  #loads show.mets.haml
      format.html  #loads show.html.haml
    end
    
    before :index do
      @remote_ip = request.env["HTTP_X_FORWARDED_FOR"] 
      @query = "*:*"
      @sort = params[:sort] || "year"
      @filter = params[:fq] || ""
      @filter = @filter.split("+>+").each{|f| f.strip!}
      @page = params[:page] || 0
      @count = params[:count] || 15
      
      @q,@docs,@facets = Index.fetch(@query, @filter, @sort, @page, @count)

      @view = params[:view] || "splash"
    end
	
    #initialize variables used by 'new.html.haml'
    before :new do  
      #if 'type' unspecified, default to first type in list
      params[:type] ||= Citation.types[0]
			
      #initialize citation subclass with any passed in citation info
      @citation = subklass_init(params[:type], params[:citation])		
    end
    
    before :show do
      @recommendations = Index.recommendations(@current_object)
    end
  end # end make_resourceful
  
  def create
    # @TODO: This step is dumb, we should map attrs in the SubClass::create method itself
    # If we have a Book object, we need to capture the Title as the new Publication Name
    if params[:type] == 'Book'
      params[:citation][:publication_full] = params[:citation][:title_primary]
    end
    
    # If we need to add a batch
    if params[:type] == "AddBatch"
    	
	  logger.debug("\n\n===ADDING BATCH CITATIONS===\n\n")	
      @citation = Citation.import_batch!(params[:citation][:citations])
      
      respond_to do |format|
        if @citation
          flash[:notice] = "Batch was successfully created."
          format.html {redirect_to new_citation_url}
          format.xml  {head :created, :location => citation_url(@citation)}
        else
          format.html {render :action => "new"}
          format.xml  {render :xml => @citation.errors.to_xml}
        end
      end

    else
      logger.debug("\n\n===ADDING SINGLE CITATION===\n\n")

      # Create the basic Citation SubKlass
      @citation = subklass_init(params[:type], params[:citation])
    
      #Update citation information based on inputs
      update_citation_info
    
      respond_to do |format|
        if @citation.save and Index.update_solr(@citation)
          flash[:notice] = "Citation was successfully created."
          format.html {redirect_to citation_url(@citation)}
          format.xml  {head :created, :location => citation_url(@citation)}
        else
          format.html {render :action => "new"}
          format.xml  {render :xml => @citation.errors.to_xml}
        end
      end # If we are adding one
    end # If we need to add a batch
  end
  
  
  def update
    @citation = Citation.find(params[:id])
    
    #First, update citation attributes (ensures deduplication keys are updated)
    @citation.attributes=params[:citation]   

    #Then, update other citation information
    update_citation_info
   
    respond_to do |format|
      if @citation.save and Index.update_solr(@citation)
        flash[:notice] = "Citation was successfully updated."
        format.html {redirect_to citation_url(@citation)}
        format.xml  {head :ok}
      else
        format.html {render :action => "edit"}
        format.xml  {render :xml => @citation.errors.to_xml}
      end
    end
  end
  
  
  # Actually update all properties of this Citation
  # This is called by both create() and update()
  def update_citation_info
    ###
    # Setting CitationNameStrings
    ###

    #default to empty array of author strings
    params[:author_name_strings] ||= [] 
            
    #Set Author NameStrings for this Citation
    @author_name_strings = params[:author_name_strings]
    citation_name_strings = Array.new
    @author_name_strings.each do |name|
      citation_name_strings << {:name => name, :role => "Author"}
    end
    @citation.citation_name_strings = citation_name_strings 
      
    ###
    # Setting Keywords
    ###
    # Save keywords to instance variable @keywords,
    # in case any errors should occur in saving citation
    @keywords = params[:keywords]
    @citation.keyword_strings = @keywords
    
    ###
    # Setting Publication Info, including Publisher
    ###
    issn_isbn = params[:issn_isbn]
    publication_info = Hash.new
    publication_info = {:name => params[:publication][:name], 
                          :issn_isbn => issn_isbn,
                          :publisher_name => params[:publisher][:name]}

    @citation.publication_info = publication_info
    
    ###
    # Setting De-Duplication keys
    ###
    @citation.issn_isbn_dupe_key = Citation.set_issn_isbn_dupe_key(@citation, citation_name_strings, issn_isbn)
    @citation.title_dupe_key = Citation.set_title_dupe_key(@citation)
    
  end
  
  
  # Load name strings list from Request params
  # and set for the current citation.
  # Also sets the instance variable @author_name_strings,
  # in case any errors should occur in saving citation
  def set_author_name_strings(citation)
  	#default to empty array of author strings
    params[:author_name_strings] ||= []	
				    
    #Set NameStrings for this Citation
    @author_name_strings = Array.new
    params[:author_name_strings].each do |add|
      name_string = NameString.find_or_initialize_by_name(add)
      @author_name_strings << {:name => name_string, :role => "Author"}
    end
    citation.citation_name_strings = @author_name_strings 	
   
 end
 
  # Load name strings list from Request params
  # and set for the current citation.
  # Also sets the instance variable @editor_name_strings,
  # in case any errors should occur in saving citation
  def set_editor_name_strings(citation)
    #default to empty array of author strings
    params[:editor_name_strings] ||= [] 
           
    #Set NameStrings for this Citation
    @editor_name_strings = Array.new
    params[:editor_name_strings].each do |add|
      name_string = NameString.find_or_initialize_by_name(add)
      @editor_name_strings << {:name => name_string, :role => "Editor"}
    end
    citation.citation_name_strings = @editor_name_strings   
   
  end
    	
  #Auto-Complete for entering Author NameStrings in Web-based Citation entry
  def auto_complete_for_author_string
    auto_complete_for_name_string(params[:author][:string])
  end
  
  #Auto-Complete for entering Editor NameStrings in Web-based Citation entry
  def auto_complete_for_editor_string
    auto_complete_for_name_string(params[:editor][:string])
  end 
  
  #Auto-Complete for entering NameStrings in Web-based Citation entry
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
      
    render :partial => 'autocomplete_list', :locals => {:objects => name_strings}
  end
  
  
  #Auto-Complete for entering Keywords in Web-based Citation entry
  #  This method provides users with a list of matching Keywords
  #  already in BibApp.
  def auto_complete_for_keyword_name
   	keyword = params[:keyword][:name].downcase
	  
    #search at beginning of word
    beginning_search = keyword + "%"
    #search at beginning of any other words
    word_search = "% " + keyword + "%"	
	  
    keywords = Keyword.find(:all, 
			  :conditions => [ "LOWER(name) LIKE ? OR LOWER(name) LIKE ?", beginning_search, word_search ], 
			  :order => 'name ASC',
			  :limit => 8)
			
    render :partial => 'autocomplete_list', :locals => {:objects => keywords}
  end    
  
  #Auto-Complete for entering Publication Titles in Web-based Citation entry
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
 
  #Auto-Complete for entering Publisher Name in Web-based Citation entry
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
        
  #Adds a single item value to list of items in Web-based Citation entry
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
	
  #Removes a single item value from list of items in Web-based Citation entry
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
  
  private
  
  # Initializes a new citation subclass, but doesn't create it in the database
  def subklass_init(klass_type, citation)
    klass_type.sub!(" ", "") #remove spaces
    klass_type.gsub!(/[()]/, "") #remove any parens
    klass = klass_type.constantize #change into a class
    if klass.superclass != Citation
      raise NameError.new("#{klass_type} is not a subclass of Citation") and return
    end
    citation = klass.new(citation)
  end
  
  def find_authorities
    @publication_authorities = Publication.find(:all, :conditions => ["id = authority_id"], :order => "name")
    @publisher_authorities = Publisher.find(:all, :conditions => ["id = authority_id"], :order => "name")
  end
end