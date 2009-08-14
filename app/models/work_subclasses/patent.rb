class Patent < Work
  validates_presence_of :title_primary

  class << self
    def roles
      ['Patent Owner']
    end
  end

end