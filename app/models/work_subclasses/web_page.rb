class WebPage < Work
  validates_presence_of :title_primary

  class << self
    def roles
      ['Author']
    end

    def creator_role
      'Author'
    end

    def contributor_role
      'Author'
    end
  end

end