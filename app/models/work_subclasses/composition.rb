class Composition < Work
   validates_presence_of :title_primary

  class << self
    def roles
      ['Composer']
    end

    def creator_role
      'Composer'
    end

    def contributor_role
      'Composer'
    end
  end

end
