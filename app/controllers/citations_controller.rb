class CitationsController < ApplicationController
  before_filter :find_authorities, :only => [:new, :edit]

  make_resourceful do
    build :index, :show, :new, :edit, :destroy
    
    publish :yaml, :xml, :json, :attributes => [
      :id, :type, :title_primary, :title_secondary, :title_tertiary,
      :year, :volume, :issue, :start_page, :end_page, :links, {
        :publication => [:id, :name]
        }, {
        :publisher => [:id, :name]
        }, {
        :author_strings => [:id, :name]
        }, {
        :people => [:id, :first_last]
        }
      ]    
    
      before :index do

        @citations = Citation.paginate(
          :all, 
          :conditions => ["citation_state_id = ?", 3],
          :order => "year desc, title_primary",
          :page => params[:page] || 1,
          :per_page => 5
        )

        @groups = Citation.find_by_sql(
          "SELECT g.*, cit.total
    	   		FROM groups g
    			JOIN (SELECT groups.id as group_id, count(distinct citations.id) as total
    					FROM citations
    					join citation_author_strings on citations.id = citation_author_strings.citation_id
    					join author_strings on citation_author_strings.author_string_id = author_strings.id
    					join pen_names on author_strings.id = pen_names.author_string_id
    					join people on pen_names.person_id = people.id
    					join memberships on people.id = memberships.person_id
    					join groups on memberships.group_id = groups.id
    					where citations.citation_state_id = 3
    					group by groups.id) as cit
    			ON g.id=cit.group_id
    			ORDER BY cit.total DESC
    			LIMIT 10"	
        )

        @people = Citation.find_by_sql(
          "SELECT p.*, cit.total
    	   		FROM people p
    			JOIN (SELECT people.id as people_id, count(distinct citations.id) as total
    					FROM citations
    					join citation_author_strings on citations.id = citation_author_strings.citation_id
    					join author_strings on citation_author_strings.author_string_id = author_strings.id
    					join pen_names on author_strings.id = pen_names.author_string_id
    					join people on pen_names.person_id = people.id
    					where citations.citation_state_id = 3
    					group by people.id) as cit
    			ON p.id=cit.people_id
    			ORDER BY cit.total DESC
    			LIMIT 10"
        )

        @publications = Citation.find_by_sql(
    	  "SELECT pub.*, cit.total
    	   		FROM publications pub
    			JOIN (SELECT publications.id as publication_id, count(distinct citations.id) as total
    					FROM citations
    					join publications on citations.publication_id = publications.id
    					where citations.citation_state_id = 3
    					group by publications.id) as cit
    			ON pub.id=cit.publication_id
    			ORDER BY cit.total DESC
    			LIMIT 10"
        )
      end
	
	#initialize variables used by 'edit.html.haml'
    before :edit do
      @author_strings = @citation.author_strings
	  @publication = @citation.publication
    end
	
	#initialize variables used by 'new.html.haml'
	before :new do  
	  #if 'type' unspecified, default to first type in list
	  params[:type] ||= Citation.types[0]
			
	  #initialize citation subclass with any passed in citation info
	  @citation = subklass_init(params[:type], params[:citation])		
	end 
  end
  
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
    
	  # Load other citation info available in request params
	  set_publication(@citation)
	  set_author_strings(@citation)
	  
	  # @TODO: This is erroring out, since we aren't yet saving all the citation fields on the "new citation" page	  
	  #Index our citation in Solr
	  #Index.update_solr(@citation)
	
      respond_to do |format|
        if @citation.save
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
    
	# Load other citation info available in request params
	set_publication(@citation)
 	set_author_strings(@citation)
	
    respond_to do |format|
      if @citation.update_attributes(params[:citation])
        flash[:notice] = "Citation was successfully updated."
        format.html {redirect_to citation_url(@citation)}
        format.xml  {head :ok}
      else
        format.html {render :action => "edit"}
        format.xml  {render :xml => @citation.errors.to_xml}
      end
    end
  end
  
  # Load publication information from Request params
  # and set for the current citation.
  # Also sets the instance variable @publication,
  # in case any errors should occur in saving citation  
  def set_publication(citation)
	#Set Publication info for this Citation
	if params[:publication] && params[:publication][:name]
		@publication = Publication.find_or_initialize_by_name(params[:publication][:name])
		citation.publication = @publication
	end  	
  end	
  
  
  # Load author strings list from Request params
  # and set for the current citation.
  # Also sets the instance variable @author_strings,
  # in case any errors should occur in saving citation
  def set_author_strings(citation)
  	#default to empty array of author strings
	params[:author_string] ||= []	
				
	#Set AuthorStrings for this Citation
	@author_strings = Array.new
	params[:author_string].each do |add|
		@author_strings << AuthorString.find_or_initialize_by_name(add)
	end
	citation.author_strings = @author_strings 	
  end	  	
  	
  #Auto-Complete for entering Author Names in Web-based Citation entry
  #  This method provides users with a list of matching AuthorStrings
  #  already in BibApp.
  def auto_complete_for_author_name
  	author_string = params[:author][:name].downcase
	
	#search at beginning of name
	beginning_search = author_string + "%"
	#search at beginning of any other words in name
	word_search = "% " + author_string + "%"	
	
	author_strings = AuthorString.find(:all, 
			:conditions => [ "LOWER(name) LIKE ? OR LOWER(name) LIKE ?", beginning_search, word_search ], 
			:order => 'name ASC',
			:limit => 8)
		  
	render :partial => 'autocomplete_author', :locals => {:author_strings => author_strings}
  end    
  
  #Adds a single author string to list of authors in Web-based Citation entry
  def add_author_to_list
  	@author_string = params[:author_string]
	
	#Add author to list dynamically using Javascript
	respond_to do |format|
		format.js { render :action => :author_list }
	end  	
  	
  end
  
  #Removes an author string from list of authors in Web-based Citation entry
  def remove_author_from_list
  	@author_string = params[:author_string]
	@remove = true
	  
	#remove author from list dynamically using Javascript
	respond_to do |format|
	  format.js { render :action => :author_list }
	end  	
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
			
	  render :partial => 'autocomplete_publication', :locals => {:publications => publications}
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