class PublishersController < ApplicationController

  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [ :new, :create, :edit, :update, :destroy ]

  # Find the @cart variable, used to display "add" or "remove" links for saved Works  
  before_filter :find_cart, :only => [:show]
  
  make_resourceful do 
    build :index, :show, :new, :edit, :create, :update

    publish :yaml, :xml, :json, :attributes => [
      :id, :name, :url, :sherpa_id, :romeo_color, :copyright_notice, :publisher_copy, {
        :publications => [:id, :name]
        }, {
        :authority => [:id, :name]
        }, {
        :works => [:id]
        }
      ]

    before :index do
      # find first letter of publisher name (in uppercase, for paging mechanism)
      @a_to_z = Publisher.letters.collect { |d| d.letter.upcase }
      
      if params[:q]
        query = params[:q]
        @current_objects = current_objects
      else
        @page = params[:page] || @a_to_z[0]
        @current_objects = Publisher.find(:all, :conditions => ["id = authority_id and upper(name) like ?", "#{@page}%"], :order => "upper(name)")
      end
    end

    before :show do
      # Recent additions list sorted by "updated_at"
      params[:sort] = "updated_at" unless params[:sort]
      @people = Person.find_all_by_publisher_id(params[:id])
      @people = Person.sort_by_most_recent_work(@people)

      # Lock current object to filters
      filter = ["publisher_id:\"#{@current_object.id}\""]
      # Add any param filters
      filter << params[:fq] if params[:fq]
      filter = filter.compact
      filter.flatten!
      
      # Default SolrRuby params
      @query        = params[:q] || "*:*" # Lucene syntax for "find everything"
      @filter       = filter.clone
      @filter_no_strip = filter.clone
      @sort         = params[:sort] || "year"
      @sort         = "year" if @sort.empty?
      @page         = params[:page] || 0
      @facet_count  = params[:facet_count] || 50
      @rows         = params[:rows] || 10
      @export       = params[:export] || ""

      @q,@works,@facets = Index.fetch(@query, @filter, @sort, @page, @facet_count, @rows)

      #@TODO: This WILL need updating as we don't have *ALL* Work info from Solr!
      # Process:
      # 1) Get AR objects (works) from Solr results
      # 2) Init the WorkExport class
      # 3) Pass the export variable and Works to Citeproc for processing

      if @export && !@export.empty?
        works = Work.find(@works.collect{|c| c["pk_i"]}, :order => "publication_date desc")
        ce = WorkExport.new
        @works = ce.drive_csl(@export,works)
      end
      
      @view = "all"
      @title = @current_object.name

      @authority_for = Publisher.find(
        :all,
        :conditions => ["authority_id = ?", current_object.id],
        :order => "name"
      )
    end

    before :new do
      #Anyone with 'editor' role (anywhere) can add publishers
      permit "editor"
      
      @publishers = Publisher.find(:all, :conditions => ["id = authority_id"], :order => "name")
      @publications = Publication.find(:all, :conditions => ["id = authority_id"], :order => "name")
    end
    
    before :create do
      #Anyone with 'editor' role (anywhere) can add publishers
      permit "editor"
    end
    
    before :edit do
      #Anyone with 'editor' role (anywhere) can update publishers
      permit "editor"
      
      @publishers = Publisher.find(:all, :conditions => ["id = authority_id"], :order => "name")
      @publications = Publication.find(:all, :conditions => ["id = authority_id"], :order => "name")
    end
    
    before :update do
      #Anyone with 'editor' role (anywhere) can update publishers
      permit "editor"
    end
  end
  
  def authorities
    #Only system-wide editors can assign authorities
    permit "editor of System"
    
    @a_to_z = Publisher.letters.collect { |d| d.letter }
    
    if params[:q]
      query = params[:q]
      @current_objects = current_objects
    else
      @page = params[:page] || @a_to_z[0]
      @current_objects = Publisher.find(:all, :conditions => ["id = authority_id and name like ?", "#{@page}%"], :order => "name")
    end    
  end

  def update_multiple
    #Only system-wide editors can assign authorities
    permit "editor of System"
    
    pub_ids = params[:pub_ids]
    auth_id = params[:auth_id]
    page = params[:page]
    
    update = Publisher.update_multiple(pub_ids, auth_id)

    respond_to do |wants|
      wants.html do
        redirect_to authorities_publishers_path(:page => page)
      end
    end
  end

  private
  
  def find_cart
    @cart = session[:cart] ||= Cart.new
  end
  
  def current_objects
    if params[:q]
      query = '%' + params[:q] + '%'
    end
    @current_objects ||= current_model.find(:all, :conditions => ["name like ?", query])
  end
end