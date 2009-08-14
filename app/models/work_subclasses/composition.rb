class Composition < Work
   validates_presence_of :title_primary

  class << self
    def roles
      ['Composer']
    end
  end

end
