class ISRC < Identifier

  validates_presence_of :name

  class << self
    def id_formats
      [:isrc]
    end
  end

end