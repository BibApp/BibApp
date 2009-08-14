class Generic < Work
  validates_presence_of :title_primary

  class << self
    def roles
      ['Creator', 'Contributor']
    end
  end

end