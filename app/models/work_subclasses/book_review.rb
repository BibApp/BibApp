class BookReview < Work

  def self.roles
    ['Author']
  end

  def self.creator_role
    'Author'
  end

  def self.contributor_role
    'Author'
  end

  def type_uri
    "http://purl.org/eprint/type/BookReview"
  end

end