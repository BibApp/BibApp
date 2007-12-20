module KeywordsHelper
  def style_for_bin(bin)
  end
  
  class YearTag
    attr_accessor :year, :tags
  end
  
  class TagDatum
    attr_accessor :id, :name, :bin, :count
    
    def initialize(tag)
      self.id = tag.id
      self.name = tag.name
      self.count = tag.count
    end
  end
end
