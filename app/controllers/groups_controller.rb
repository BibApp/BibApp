class GroupsController < ApplicationController
  make_resourceful do 
    build :all, :update

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
      @a_to_z = Group.letters.collect { |g| g.letter }
      @page = params[:page] || @a_to_z[0]
      @current_objects = Group.find(
        :all, 
        :conditions => ["name like ?", "#{@page}%"], 
        :order => "name"
      )
    end
    
    before :show do
      # Default SolrRuby params
      @query        = @current_object.solr_id
      @filter       = params[:fq] || ""
      @filter       = @filter.split("+>+").each{|f| f.strip!}
      @sort         = params[:sort] || "year"
      @page         = params[:page] || 0
      @facet_count  = params[:facet_count] || 50
      @rows         = params[:rows] || 10
      
      @q,@docs,@facets = Index.fetch(@query, @filter, @sort, @page, @facet_count, @rows)
      
      @view = "all"
      @title = @current_object.name
    end
    
    before :new, :edit do 
      @groups = Group.find(:all, :order => "name")
    end
  end
  
  def create_group
    @group = Group.find_or_create_by_name(params[:group][:name])
    redirect_to new_group_path
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
  
end
