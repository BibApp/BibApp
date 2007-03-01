class SearchController < ApplicationController

  def index
    if params[:q]
      @query = params[:q]
      @query = "%" + @query + "%"
      
      @people = Person.find_by_sql([
        "select * from people
        where first_last like ?
        order by first_name", @query])

      @groups = Group.find_by_sql([
        "select * from groups
        where name like ?
        order by name", @query])
    end
  end
  
  def experts
    @query = params['query']
    @prep_query = "%" + @query + "%"
    @people_results = Person.find_by_sql([  
      "Select p.*, count(c.id) as papers, max(c.pub_year) as recency
      From citations c
      join authorships au on c.id = au.citation_id
      join people p on au.person_id = p.id
      where citation_state_id = 3
      and c.keywords like ?
      or c.abstract like ?
      or c.title_primary like ?
      group by p.id
      order by max(pub_year) DESC, count(c.id) DESC
      limit 10", @prep_query, @prep_query, @prep_query])
      
    @group_results = Group.find_by_sql([
      "select g.*, count(c.id) as papers, max(c.pub_year) as recency
      from citations c
      join authorships au on c.id = au.citation_id
      join people p on au.person_id = p.id
      join memberships m on m.person_id = p.id
      join groups g on m.group_id = g.id
      where citation_state_id = 3
      and c.title_primary like ?
      or c.abstract like ?
      or c.keywords like ?
      group by g.id
      order by count(c.id) DESC
      limit 5", @prep_query, @prep_query, @prep_query])
  end
  
  def results
    @query = params[:query]
    @results = Person.find_by_sql([
      "select * from people
      where last_name like ?
      or first_name like ?
      order by last_name, first_name", @query, @query])
  end
end
