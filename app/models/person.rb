class Person < ActiveRecord::Base
  
  acts_as_authorizable  #some actions on people require authorization
 
  serialize :scoring_hash
  has_many :name_strings, :through => :pen_names
  has_many :pen_names
  has_many :groups, :through => :memberships, :conditions => ["groups.hide = ?", false]
  has_many :memberships
  
  # Association Extensions - Read more here:
  # http://blog.hasmanythrough.com/2006/3/1/association-goodness-2
  
  has_many :citations, :through => :contributorships 

  has_many :contributorships do 
    # Show only non-hidden contributorships
    # @TODO: Maybe include a "score" threshold here as well?
    # - Like > 50 we show on the person view, 'cuz they probably wrote it?
    # - Like < 50 we don't show, 'cuz maybe they didn't write it?
    def to_show 
      find(
        :all, 
        :conditions => [
          "contributorships.hide = ? and contributorships.contributorship_state_id = ?", 
          false, 
          2
        ],
        :include => [:citation]
      )
    end
    
    def unverified
      find(:all, :conditions => ["contributorships.contributorship_state_id = >", 1], :include => [:citation], :order => "citations.publication_date desc")
    end
    
    def verified
      # ContributorshipStateId 2 = Verifed
      find(:all, :conditions => ["contributorships.contributorship_state_id = ?", 2], :include => [:citation], :order => "citations.publication_date desc")
    end
    
    def denied
      # ContributorshipStateId 3 = Denied
      find(:all, :conditions => ["contributorships.contributorship_state_id = ?", 3],:include => [:citation], :order => "citations.publication_date desc")
    end
  end
  
  has_one :image, :as => :asset
  

  def name
    "#{first_name} #{last_name}"
  end
  
  def first_last
    "#{first_name} #{last_name}"
  end
  
  def last_first
    "#{last_name}, #{first_name}"
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
    suggestions = NameString.find(
      :all, 
      :conditions => ["name like ?", "%" + self.last_name + "%"],
      :order => :name
    )
    
    # TODO: do this right. The vector subtraction is dumb.
    return suggestions - name_strings
  end
  
  # Person Contributorship Calculation Fields
  def verified_publications
    Contributorship.find_all_by_person_id_and_contributorship_state_id(self.id,2,:include=>[:citation])
  end
  
  def update_scoring_hash
    vps = self.verified_publications
    
    known_years = vps.collect{|vp| 
                 if !vp.citation.publication_date.nil?
                   vp.citation.publication_date.year 
                 end
                   }.uniq
   known_years.delete(nil)

    
    known_publication_ids = vps.collect{|vp| vp.citation.publication.id}.uniq
    known_collaborator_ids = vps.collect{|vp| vp.citation.name_strings.collect{|ns| ns.id}}.flatten.uniq
    known_keyword_ids = vps.collect{|vp| vp.citation.keywords.collect{|k| k.id}}.flatten.uniq
    
    # Return a hash comprising all the Contributorship scoring methods
    scoring_hash = {
      :years => known_years.sort, 
      :publication_ids => known_publication_ids,
      :collaborator_ids => known_collaborator_ids,
      :keyword_ids => known_keyword_ids
    }
    self.update_attribute(:scoring_hash, scoring_hash)
  end
  
  #A person's image file
  def image_url
    if !self.image.nil?
      self.image.public_filename
    else
      "man.jpg"
    end
    
  end
  
  # Convert object into semi-structured data to be stored in Solr
  def to_solr_data
    "#{last_name}||#{id}||#{image_url}"
  end

  class << self
    # return the first letter of each name, ordered alphabetically
    def letters
      find(
        :all,
        :select => 'DISTINCT SUBSTR(last_name, 1, 1) AS letter',
        :order  => 'letter'
      )
    end
    
    #Parse Solr data (produced by to_solr_data)
    # return Person last_name, ID, and Image URL
    def parse_solr_data(person_data)
      data = person_data.split("||")
      last_name = data[0]
      id = data[1]  
      image_url = data[2]
      
      return last_name, id, image_url
    end
  end
end