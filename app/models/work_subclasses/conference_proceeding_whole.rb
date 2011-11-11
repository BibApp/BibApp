class ConferenceProceedingWhole < Work

  def self.roles
    ['Editor']
  end

  def self.creator_role
    'Editor'
  end

  def self.contributor_role
    'Editor'
  end

  def type_uri
    "http://purl.org/eprint/type/ConferenceItem"
  end

end
