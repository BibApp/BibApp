require 'lib/trivial_initializer'
module KeywordsHelper

  class YearTag
    include TrivialInitializer
    attr_accessor :year, :tags
  end

  class TagDatum
    include TrivialInitializer
    attr_accessor :id, :name, :bin, :count, :year
  end

end
