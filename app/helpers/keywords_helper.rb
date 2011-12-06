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
    link_to "#{object.name}", url_for(object) + ' - ' + t('common.keywords.timeline')
  end

  def timeline_list_filter(tag, object)
    Array.new.tap do |filter|
      filter << %Q(keyword_facet: "#{tag.name}")
      filter << %Q(year_facet: "#{tag.year}")
      if object
        filter << %Q(#{object.class.to_s.downcase}_facet: "#{object.name}")
      end
    end
  end

end
