module KeywordsHelper
  def style_for_bin(bin)
  end

  class YearTag
    attr_accessor :year, :tags
  end

  class TagDatum
    attr_accessor :id, :name, :bin, :count, :year

    def initialize(args = {})
      args.each do |k, v|
        self.send(:"#{k}=", v)
      end
    end
  end

end
