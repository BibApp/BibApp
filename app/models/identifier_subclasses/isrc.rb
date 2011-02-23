class ISRC < Identifier

  validates_presence_of :name

  class << self
    def id_formats
      [:isrc]
    end
  end

  #TODO fill in class to make it actually do something
end