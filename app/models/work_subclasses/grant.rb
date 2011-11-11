class Grant < Work

  def self.roles
    ['Principal Investigator', 'Co-Principal Investigator']
  end

  def self.creator_role
    'Principal Investigator'
  end

  def self.contributor_role
    'Co-Principal Investigator'
  end

  def type_uri
    "http://purl.org/eprint/type/ScholarlyText"
  end
end