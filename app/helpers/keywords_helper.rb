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

  def body_header(object)
    link_to "#{object.name}", url_for(object) + ' - Timeline'
  end

end
