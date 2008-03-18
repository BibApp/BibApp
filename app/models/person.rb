class Person < ActiveRecord::Base
  has_many :name_strings, :through => :pen_names
  has_many :pen_names
  has_many :groups, :through => :memberships
  has_many :memberships
  has_many :citations, :through => :authorships
  has_many :authorships

  def first_last
    "#{first_name} #{last_name}"
  end
  
  def to_param
    param_name = first_last.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end
  

  def groups_not
    all_groups = Group.find(:all, :order => "name")
    # TODO: do this right. The vector subtraction is dumb.
    return all_groups - groups
  end
  
  def name_strings_not
    all_name_strings = NameString.find(:all, :order => "name")
    # TODO: do this right. The vector subtraction is dumb.
    return all_name_strings - name_strings
  end
  
  # Person Contributorship Calculation Fields
  def verified_publications
    Authorship.find_all_by_person_id_and_authorship_state_id(self.id,2)
  end
  
  def known_years
    # Build an array of verified publication year strings
    # Ex. ["2001,2002,..."]
    self.verified_publications.collect{|vp| vp.citation.year}.uniq
  end
  
  def known_publication_ids
    # Build an array of verified publication objects
    # Ex. [#<Publication id: 1...>,#<Publication id: 2...>,..."]
    self.verified_publications.collect{|vp| vp.citation.publication.id}.uniq
  end
  
  def known_collaborator_ids
    # Build an array of verified name_string objects
    # Ex. [#<NameString id: 1...>,#<NameString id: 2...>,..."]    
    self.verified_publications.collect{|vp| vp.citation.name_strings.collect{|ns| ns.id}}.flatten.uniq
  end
  
  def known_keyword_ids
    # Build an array of verified keyword objects
    # Ex. [#<Keyword id: 1...>,#<Keyword id: 2...>,..."]
    self.verified_publications.collect{|vp| vp.citation.keywords.collect{|k| k.id}}.flatten.uniq
  end
  
  def scoring_hash
    # Return a hash comprising all the Contributorship scoring methods
    scoring_hash = {
      :years => self.known_years, 
      :publication_ids => self.known_publication_ids,
      :collaborator_ids => self.known_collaborator_ids,
      :keyword_ids => self.known_keyword_ids
    }
    scoring_hash
  end
end