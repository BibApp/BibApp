module KeywordsHelper
  def style_for_bin(bin)
  end

  class YearTag
    attr_accessor :year, :tags
  end

  class TagDatum
    attr_accessor :id, :name, :bin, :count, :year

    def initialize(tag)
      self.name = tag.name
      self.count = tag.count
      self.year = tag.year
    end
  end
end
