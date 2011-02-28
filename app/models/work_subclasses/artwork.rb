class Artwork < Work
  validates_presence_of :title_primary

  def self.roles
    ['Artist', 'Curator']
  end

  def self.creator_role
    'Artist'
  end

  def self.contributor_role
    'Curator'
  end

  def type_uri
    "http://purl.org/dc/dcmitype/Image" #DCMI Type
  end
end