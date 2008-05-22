class GroupsController < ApplicationController
  make_resourceful do 
    build :all, :update

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
      @query = @current_object.solr_id
      @filter = params[:fq] || ""
      @filter = @filter.split("+>+").each{|f| f.strip!}
      @sort = params[:sort] || "year"
      @page = params[:page] || 0
      @q,@docs,@facets = Index.fetch(@query, @filter, @sort, @page)

      @title = @current_object.name
    end
  end
  
  def create_group
    @group = Group.find_or_create_by_name(params[:group][:name])
    redirect_to new_group_path
  end
end
