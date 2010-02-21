class ConferencePoster < Work
  validates_presence_of :title_primary

  class << self
    def roles
      ['Author', 'Editor']
    end

    def creator_role
      'Author'
    end

    def contributor_role
      'Editor'
    end
  end

end