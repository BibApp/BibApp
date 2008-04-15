class GroupsController < ApplicationController
  make_resourceful do 
    build :all

    before :index do
      @groups = Group.paginate(
        :all,
        :order => "name",
        :page => params[:page] || 1,
        :per_page => 10
      )
    end
    
    before :show do 
      @query = @current_object.solr_id
      @filter = params[:fq] || ""
      @filter = @filter.split("+>+").each{|f| f.strip!}
      @q,@docs,@facets = Index.fetch(@query, @filter)
      
      logger.debug("\n\n Facets: #{@facets.inspect}\n\n")
      
      @title = @current_object.name
    end
  end
end
