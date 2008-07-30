class GroupsController < ApplicationController
  
  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [ :new, :create, :edit, :update, :destroy, :hide ]
  
  make_resourceful do 
    build :all

    publish :xml, :json, :yaml, :attributes => [
      :id, :name, :url, :description,
       {:people => [:id, :name]}
    ]
    
    #Add a response for RSS
    response_for :show do |format| 
      format.rss  #loads show.rss.rxml
      format.html  #loads show.html.haml
    end
    
    before :index do
      # find first letter of group names (in uppercase, for paging mechanism)
      @a_to_z = Group.letters.collect { |g| g.letter.upcase }
      
      @page = params[:page] || @a_to_z[0]
      @current_objects = Group.find(
        :all, 
        :conditions => ["upper(name) like ? AND hide = ?", "#{@page}%", false], 
        :order => "upper(name)"
      )
    end
    
    before :show do
      # Default SolrRuby params
       @query        = @current_object.solr_id
       @filter       = params[:fq] || ""
       @filter_no_strip = params[:fq] || ""
       @filter       = @filter.split("+>+").each{|f| f.strip!}
       @sort         = params[:sort] || "year"
       @sort         = "year" if @sort.empty?
       @page         = params[:page] || 0
       @facet_count  = params[:facet_count] || 50
       @rows         = params[:rows] || 10
       @export       = params[:export] || ""

       @q,@docs,@facets = Index.fetch(@query, @filter, @sort, @page, @facet_count, @rows)

       @citations = Array.new
       @docs.each do |citation, score|
         @citations << citation
       end

       if @export && !@export.empty?
         x = CitationExport.new
         @citations = x.drive_csl(@export, @citations)
       end
      
        @view = "all"
        @title = @current_object.name
      
        @feeds = [{
          :action => "show",
          :id => @current_object.id,
          :format => "rss"
        }]
    end
    
    before :new do
     @groups = Group.find(:all, :order => "name")
    end
   
    
    before :edit do
      #'editor' of group can edit that group
      permit "editor of group"
      
      @groups = Group.find(:all, :order => "name")
    end
  end
  
  def create_group
    
    @duplicategroup = Group.find(:first, :conditions => ["name LIKE ?", params[:group][:name]])
   
    
    if @duplicategroup.nil?
      @group = Group.find_or_create_by_name(params[:group][:name])
      @group.hide = false
      @group.save
     
      respond_to do |format|
       flash[:notice] = "Group was successfully created."
       format.html {redirect_to group_url(@group)}
      end
    else
      respond_to do |format|
       flash[:notice] = "This group already exists"
       format.html {redirect_to new_group_path}
      end
    end
  end
  
  def auto_complete_for_group_name
    group_name = params[:group][:name].downcase
    
    #search at beginning of name
    beginning_search = group_name + "%"
    #search at beginning of any other words in name
    word_search = "% " + group_name + "%"
    
    groups = Group.find(:all, 
          :conditions => [ "LOWER(name) LIKE ? OR LOWER(name) LIKE ?", beginning_search, word_search ], 
        :order => 'name ASC',
        :limit => 8)
      
    render :partial => 'autocomplete_list', :locals => {:objects => groups}
  end 
  
  def hide
    @group = Group.find(params[:id])
    @group.hide = true
    @group.save
      respond_to do |format|
       flash[:notice] = "Group was successfully removed."
       format.html {redirect_to :action => "index"}
      end
  end
  
end