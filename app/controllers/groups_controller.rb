class GroupsController < ApplicationController
  make_resourceful do 
    build :all

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
      @sort = params[:sort] || "year desc"
      @fetch = @query + ";" + @sort
      @filter = params[:fq] || ""
      @filter = @filter.split("+>+").each{|f| f.strip!}
      @q,@docs,@facets = Index.fetch(@fetch, @filter, @sort)

      @title = @current_object.name
    end
  end
end
