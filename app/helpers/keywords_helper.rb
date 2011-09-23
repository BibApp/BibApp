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
    link_to "#{@current_object.name}", url_for(@current_object) + ' - Timeline'
  end

end
