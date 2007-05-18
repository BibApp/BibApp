class SearchController < ApplicationController

  def index
    if params[:q]
      @query = params[:q]
      @query.downcase
      @query = "%" + @query + "%"
      
      @people = Person.find(:all,
                :conditions=>["LOWER(first_name) LIKE ? OR
                               LOWER(last_name) LIKE ?", @query, @query],
                :order=>"first_name")

      @groups = Group.find(:all,
                :conditions=>["LOWER(name) LIKE ?", @query],
                :order=>"name")
    end
  end
  
  def experts
    @query = params['query']
    @prep_query = "%" + @query + "%"

    # In order to search tags, we need a version of 
    # the query where we've replaced all spaces with '-'
    @prep_tag_query = @prep_query.gsub(/\s+/, '-')
    
    #This query should work in both MySQL and Postgres
    @people_results = Person.find_by_sql([
      "Select per.*, cit.papers, cit.recency
      From people per
      JOIN (SELECT p.id as person_id, count(c.id) as papers, max(c.pub_year) as recency 
            From citations c 
              join authorships au on c.id = au.citation_id 
              join people p on au.person_id = p.id
              join taggings tg on c.id=tg.taggable_id
              join tags t on tg.tag_id=t.id
            where citation_state_id = 3 
            and t.name like ? 
            or c.abstract like ? 
            or c.title_primary like ?
            group by p.id) as cit
      ON per.id=cit.person_id
      order by cit.recency DESC, cit.papers DESC
      limit 10", @prep_tag_query, @prep_query, @prep_query])
      
      #This query should work in both MySQL and Postgres
      @group_results = Group.find_by_sql([
      "Select grp.*, cit.papers, cit.recency
        From groups grp
        JOIN (select g.id as group_id, count(c.id) as papers, max(c.pub_year) as recency
              from citations c
                join authorships au on c.id = au.citation_id
                join people p on au.person_id = p.id
                join memberships m on m.person_id = p.id
                join groups g on m.group_id = g.id
                join taggings tg on c.id=tg.taggable_id
                join tags t on tg.tag_id=t.id
              where citation_state_id = 3
              and t.name like ? 
              or c.abstract like ? 
              or c.title_primary like ?
              group by g.id) as cit
      ON grp.id=cit.group_id 
      order by cit.papers DESC
      limit 5", @prep_tag_query, @prep_query, @prep_query])
  end
  
  def results
    @query = params[:query]
    @query.downcase
    @query = "%" + @query + "%"
    
    
    @results = Person.find(:all,
        :conditions=>["LOWER(first_name) LIKE ? OR
                       LOWER(last_name) LIKE ?", @query, @query],
        :order=>"last_name, first_name")
  end
end
