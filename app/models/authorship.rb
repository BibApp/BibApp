class Authorship < ActiveRecord::Base
  belongs_to :person
  belongs_to :citation
  
  validates_uniqueness_of :citation_id, :scope => :person_id
  
  class << self
    def create_batch!(person, citation_data)
      cites = Citation.import_batch!(citation_data)
      create_batch_from_citations!(person, cites)
      return cites
    end
  
    def create_batch_from_citations!(person, citations)
      return if not citations.respond_to? :each
      citations.each do |c|
        Authorship.create(:person_id => person.id, :citation_id => c.id )
        c.update_attribute(:imported_for, person.id)
      end
    end
  
    def coauthors_of(person)
      # Allow us to get either an ID or an ActiveRecord; we need ID
      if person.instance_of?(Fixnum)
        person_id = person
      else
        person_id = person.id
      end
    
       #Find People this author has co-authored with
       # (This query should be valid in both MySQL and PostgreSQL) 
      Person.find_by_sql(
         ["SELECT p.*, coauth.pub_count 
           FROM people p
           JOIN (SELECT p.id as person_id, count(a2.person_id) as pub_count
                 FROM authorships a1, authorships a2, people p
                 WHERE a1.citation_id = a2.citation_id
                 AND a1.person_id <> a2.person_id
                 AND a1.person_id = ?
                 AND a2.person_id = p.id
                 GROUP BY p.id) AS coauth
           ON p.id=coauth.person_id      
           ORDER BY coauth.pub_count DESC
           LIMIT 10", person_id])
    end
  
    def coauthor_groups(person)
      # Allow us to get either an ID or an ActiveRecord; we need ID
      if person.instance_of?(Fixnum)
        person_id = person
      else
        person_id = person.id
      end
    
       #Find Groups whose members this author has co-authored with
       # (This query should be valid in both MySQL and PostgreSQL) 
      Group.find_by_sql(
         ["SELECT g.*, g_auth.pub_count 
           FROM groups g
           JOIN (SELECT g.id as group_id, count(distinct coauths.citation_id) as pub_count
                 FROM authorships a1
                 JOIN authorships coauths ON a1.citation_id = coauths.citation_id
                 JOIN memberships m ON m.person_id = coauths.person_id
                 JOIN groups g ON m.group_id = g.id
                 WHERE a1.person_id = ?
                 GROUP by g.id) AS g_auth
           ON g.id=g_auth.group_id      
           ORDER BY g_auth.pub_count DESC", person_id])
    end
    
    def top_authors(count = 25)
       #Find authors with the most authorships/publications
       # (This query should be valid in both MySQL and PostgreSQL) 
      people = Person.find_by_sql(
         ["SELECT p.*, au.pub_count
			 FROM people p JOIN (
				 SELECT au.person_id, count(au.id) as pub_count
				 FROM authorships au
				 GROUP BY au.person_id
				 HAVING count(au.id) > 0
				 ORDER BY pub_count DESC
				 LIMIT ?) AS au
			 ON p.id = au.person_id
			 ORDER BY au.pub_count DESC", count])
    end
  end
end
