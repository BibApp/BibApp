class BookReview < Work
  validates_presence_of :title_primary

  class << self
    def roles
      ['Author']
    end
  end

end