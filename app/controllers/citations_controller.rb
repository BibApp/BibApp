class CitationsController < ApplicationController
  before_filter :find_authorities, :only => [:new, :edit]

  make_resourceful do
    build :index, :show, :edit, :destroy
    
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
    
    before :edit do
      auto_complete_for :author_strings, :name
      @author_strings = @citation.author_strings
    end
  end
  
  def new
    params[:type] ||= 'Add Batch'

    # @TODO: Add each citation subklass to this array
    # "Journal Article", 
    # "Conference Proceeding", 
    # "Book"
    # more...
    
    @citation_types = [
        "Add Batch",
    ]
    
    @citation = subklass_init(params[:type], params[:citation])

  end
  
  def create
    
    # @TODO: This step is dumb, we should map attrs in the SubClass::create method itself
    # If we have a Book object, we need to capture the Title as the new Publication Name
    if params[:type] == 'Book'
      params[:citation][:publication_full] = params[:citation][:title_primary]
    end
    
    # If we need to add a batch
    if params[:type] == "AddBatch"
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
      # @TODO: Finish single citation entry?
      # If we need to add just one
      # Initiate the Citation SubKlass
      @citation = subklass_init(params[:type], params[:citation])
    
      authors = Array.new
      authorships = Array.new

      params[:author].each do |add|
        author = Author.find_or_create_by_name(add)
        authors << author.name
        authorships << author.id
      end
    
      @citation.serialized_data = { "authors" => authors, "authorships" => authorships }
    
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
    author_strings = params[:author_strings]
    author_strings.each do |id, hash|
      row = AuthorString.find(id)
      row.update_attributes(:name => hash[:name])
    end

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
  
  private
  
  def subklass_init(klass_type, citation)
    klass_type.sub!(" ", "")
    klass = klass_type.constantize
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