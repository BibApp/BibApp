class KeywordsController < ApplicationController
  
  caches_page :timeline
  
  def timeline
    @group = Group.find(params[:id])
    @year_tags = @group.tags_by_year
    @all_tags = @year_tags.collect { |yeardata| yeardata.tags.collect {|t| t.name}}.flatten.uniq.sort
  end
  
end
