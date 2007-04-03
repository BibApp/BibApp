class Person < ActiveRecord::Base
  require 'namecase'
  
  composed_of :name, 
              :class_name => Name,
              :mapping => 
              [ # database ruby 
                [ :last_name, :last ],
                [ :first_name, :first ], 
                [ :middle_name, :middle ]
              ]
              
  before_save   :set_first_last

  has_many :memberships
  has_many :groups,
    :through  => :memberships,
    :order    => "name"    
  
  has_many :authorships
  has_many :citations,
    :through => :authorships,
    :order  =>  "pub_year DESC"
    
  has_many :recent_citations,
    :class_name => "Citation",
    :source => :citation,
    :through => :authorships,
    :order => "pub_year DESC, id DESC",
    :limit => 5
  
  def groups_not
    all_groups = Group.find(:all, :order => "name")
    # TODO: do this right. The vector subtraction is dumb.
    return all_groups - groups
  end
      
  def to_param
    param_name = display_name.gsub(" ", "_")
    "#{id}-#{param_name}"
  end

  def display_name_reversed
    name = "#{last_name}, #{first_name}"
    nc_name = NameCase.new(name)
    return nc_name.nc!
  end
  
  def display_name
    name = "#{first_name} #{last_name}"
    nc_name = NameCase.new(name)
    return nc_name.nc!
  end
  
  def image
    image = "#{image_url}"
    if image.empty?
      image = '/images/question_mark.png'
    end
    return image
  end
  
  def first_name_nc
    name = "#{first_name}"
    nc_name = NameCase.new(name)
    return nc_name.nc!
  end
  
  def last_name_nc
    name = "#{last_name}"
    nc_name = NameCase.new(name)
    return nc_name.nc!
  end
  
  def publication_reftypes
    publication_reftypes = Person.find_by_sql(
      ["select reftype_id, refworks_reftype, count(reftype_id) as count from citations
      join reftypes on (reftype_id = refworks_id) 
      join authorships on (citations.id = authorships.citation_id)
      where authorships.person_id = ?
      group by reftype_id
      order by reftype_id", id]
    )
  end
  
  def favorite_publications
    favorite_publications = Person.find_by_sql(
      ["select count(c.id) as count, c.issn_isbn, c.periodical_full as full_name, c.title_tertiary
      from citations c
      join authorships au on c.id = au.citation_id
      left join publications publ on c.publication_id = publ.id
      left join publishers pub on publ.publisher_id = pub.id
      where au.person_id = ?
      and length(c.issn_isbn) > 0
      and c.citation_state_id = 3
      group by c.issn_isbn 
      order by count DESC, c.periodical_full
      limit 10", id]
    )
    favorite_publications.each{|p| p.full_name = p.title_tertiary if p.full_name.empty?}
  end
  
  def favorite_publishers
    favorite_publishers = Person.find_by_sql(
      ["select count(title_primary) as count, publisher as full_name
      from citations 
      join authorships on (citations.id = authorships.citation_id)
      where length(publisher) > 0 and authorships.person_id = ?
      group by publisher 
      order by count DESC
      limit 10", id]
    )
  end
  
  def sherpa_publishers
    distinct_publishers = Publisher.find_by_sql(
      ["select distinct(pub.name) as publisher_name, count(c.title_primary) as count, pub.romeo_colour
      from citations c
      join authorships au on (c.id = au.citation_id)
      left join publications publ on (c.publication_id = publ.id)
      left join publishers pub on publ.publisher_id = pub.id
      where au.person_id = ?
      group by publisher_name
      order by pub.name ASC", id]
    )
  end
  
  def sherpa_publications
    distinct_publishers = Publication.find_by_sql(
      ["select distinct(publ.name) as publication_name, count(c.title_primary) as count, pub.name as publisher_name
      from citations c
      join authorships au on (c.id = au.citation_id)
      left join publications publ on (c.publication_id = publ.id)
      left join publishers pub on publ.publisher_id = pub.id
      where au.person_id = ?
      and length(c.issn_isbn) > 0
      group by publ.name
      order by publ.name ASC", id]
    )
  end

  def tags(count)
    tags = Tag.find_by_sql(
      ["select count(taggings.tag_id) as count, name 
      from tags
      join taggings on (tags.id = taggings.tag_id)
      join citations on (taggings.taggable_id = citations.id)
      join authorships on (citations.id = authorships.citation_id)
      where authorships.person_id = ?
      group by name
      order by count DESC
      limit ?", id, count]
    )
  end
  
  def copyright_analysis
    blank = ""
    copyright_analysis = Person.find_by_sql(
      ["select count(c.id) as count, c.issn_isbn, c.periodical_full, c.title_tertiary,
          pub.sherpa_id, pub.name as publisher, pub.romeo_colour
      from citations c
      join authorships au on c.id = au.citation_id
      left join publications publ on c.publication_id = publ.id
      left join publishers pub on publ.publisher_id = pub.id
      where au.person_id = ?
      and c.citation_state_id = 3
      group by c.issn_isbn 
      order by count DESC, c.periodical_full", id]
    )
  end
  
  def set_first_last
    self.first_last = "#{self.first_name} #{self.last_name}"
  end
  
end
