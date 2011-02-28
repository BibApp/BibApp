class Generic < Work
  validates_presence_of :title_primary

  def self.roles
    ['Creator', 'Contributor']
  end

  def self.creator_role
    'Creator'
  end

  def self.contributor_role
    'Contributor'
  end

  def type_uri
    "http://purl.org/eprint/type/ScholarlyText"
  end
end