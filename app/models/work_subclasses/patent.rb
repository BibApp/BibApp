class Patent < Work
  validates_presence_of :title_primary

  class << self
    def roles
      ['Patent Owner']
    end

    def creator_role
      'Patent Owner'
    end

    def contributor_role
      'Patent Owner'
    end
  end

end