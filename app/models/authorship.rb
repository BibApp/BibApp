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
    
      Person.find_by_sql(
      ["select p.*, count(a2.person_id) as pub_count from authorships a1, authorships a2, people p
      where a1.citation_id = a2.citation_id
      and a1.person_id <> a2.person_id
      and a1.person_id = ?
      and a2.person_id = p.id
      group by a2.person_id
      order by pub_count desc
      limit 10", person_id])
    
    end
  
    def coauthor_groups(person)
      # Allow us to get either an ID or an ActiveRecord; we need ID
      if person.instance_of?(Fixnum)
        person_id = person
      else
        person_id = person.id
      end
    
      Group.find_by_sql(
      ["select g.*, count(distinct coauths.citation_id) as pub_count from authorships a1
      join authorships coauths on a1.citation_id = coauths.citation_id
      join memberships m on m.person_id = coauths.person_id
      join groups g on m.group_id = g.id
      where a1.person_id = ?
      group by g.id, g.name, g.suppress, g.created_at
      order by pub_count desc", person_id])
    
    end
    def top_authors(count = 25)
      people = Person.find_by_sql(
        ["SELECT p.*, count(au.id) as pub_count FROM people p
          JOIN authorships au ON p.id = au.person_id
          GROUP BY p.id
          HAVING count(au.id) > 0
          ORDER BY pub_count DESC
          limit ?", count])
    end
  end
end
