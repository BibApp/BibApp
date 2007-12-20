class GroupsController < ApplicationController
  
  layout "application", :except => ["dot"]
  
  def index
    @groups_count        = Group.count
    if @groups_count < 1
      # redirect_to :controller => :account, :action => :signup
    end
    @people_count        = Authorship.count('person_id', :distinct => true)
    @archive_count       = Citation.count(
                            :conditions => "archive_status_id in (2,4,5,6,7) and citation_state_id = 3")
    @people              = Authorship.top_authors(30)
    @publications        = Publication.favorites
    @publishers          = Publisher.favorites
    
    @tags = Tag.find_by_sql(
      "SELECT tags.id, tags.name, count(tags.id) as count
      FROM tags
      JOIN taggings ON tags.id = taggings.tag_id
      GROUP BY tags.id, tags.name
      ORDER BY count DESC
      LIMIT 50")
  end
  
  def show
    url_abbrev = params[:url_abbrev]
    @group = Group.find(params[:id])
    @citation_count = @group.citation_count[0]['count']
    
    # Build the people list, using rails auto-pagination
    @people_pages, @people = pagination @group.people_who_have_published,
     :page => params[:page],
     :per_page => params[:per_page]    
    
    @rss_feeds = [{
      :controller => "rss",
      :action => "person",
      :id => @group.id
    }]
  end
  
  def dot    
    @group = Group.find(params[:id])                                  
    @coauthorships = Hash.new
    
    @group.people_who_have_published.each do |person|
      coauths = Array.new
      coauths = Authorship.coauthors_of(person)
      coauth_names = Array.new
      coauths.each do |coauth|
        coauth_names << coauth.display_name
      end
      
      @coauthorships[person.display_name] = [coauth_names]
    end
  end
  
  def create
  end
end
