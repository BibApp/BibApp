class DissertationThesis < Work

  def self.roles
    ['Author', 'Advisor', 'Committee Chair', 'Committee Member', 'Director of Research']
  end

  def self.creator_role
    'Author'
  end

  def self.contributor_role
    'Committee Member'
  end

  def type_uri
    "http://purl.org/eprint/type/Thesis"
  end
end