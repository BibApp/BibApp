class Patent < Work

  def self.roles
    ['Patent Owner']
  end

  def self.creator_role
    'Patent Owner'
  end

  def self.contributor_role
    'Patent Owner'
  end

  def type_uri
    "http://purl.org/eprint/type/Patent"
  end

end