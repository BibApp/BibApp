class Artwork < Work
  validates_presence_of :title_primary

  class << self
    def roles
      ['Artist', 'Curator']
    end
  end

end