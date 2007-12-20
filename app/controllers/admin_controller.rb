class AdminController < ApplicationController
  def index
  end
  
  def archive
    if request.post?
      citation = Citation.find(params[:id])
      if citation
        citation.archive_status_id = 4 if params[:saved]
        citation.bump_value += 1 if params[:bottom]
        citation.archive_status_id = 3 if params[:forgetit]
        citation.save
      end
    end
    @citations = Citation.find(:all, 
      :conditions => ["archive_status_id = ? and citation_state_id = ?", 2, 3], 
      :limit => 3, 
      :order => 'bump_value')
    @citation_count = Citation.count(:conditions => ["archive_status_id = ? and citation_state_id = ?", 2, 3])
  end

  def feeds
    @count = Feed.find(:all, :conditions => "feed_state_id = 1")
    if @count.size > 0
      @citation = Feed.find(:first, :conditions => "feed_state_id = 1")
      @person = Person.find_by_id(@citation.person_id)
    else
      @citation = nil
      @person = nil
    end
  end
  
  def mark_as_archived
    # Example batch import return from DSpace
    # TODO: Make this accept a text file
    citations = "1 1960/10124
    1026 1960/10126
    1031 1960/10128
    1033 1960/10130"
    
    update = Array.new
    citations.each_line do |add|
      update << add.split(" ")
    end
    
    update.each do |add|
      begin
        logger.debug "Citation ID:#{add[0]}"
        change = Citation.find(add[0])
        change.update_attributes("archive_status_id" => 7, "handle" => "#{add[1]}")
      rescue Exception => e
      end
    end
  end
  
end
