class ISRC < Identifier

  validates_presence_of :name

  def self.id_formats
    [:isrc]
  end

  #TODO fill in class to make it actually do something
end