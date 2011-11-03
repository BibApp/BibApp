require 'set'
module KeywordCloudHelper
  def set_keywords(facets)
    if facets[:keywords].present?
      max = 10
      bin_count = 5
      kwords = exclude_keywords(facets[:keywords]).first(max)
      max_kw_freq = kwords[0].value.to_i > bin_count ? kwords[0].value.to_i : bin_count
      s = get_keyword_struct
      kwords.map { |kw|
        bin = ((kw.value.to_f * bin_count.to_f) / max_kw_freq).ceil
        s.new(kw.name, bin)
      }.sort { |a, b| a.name <=> b.name }
    else
      []
    end
  end

  protected

  def get_keyword_struct
    Struct.new(:name, :count)
  end

  def load_keyword_exclusions
    (YAML.load_file(File.join(Rails.root, 'config', 'keyword_exclusions.yml')) || []) rescue []
  end

  #Note - as I'm thinking now we may require two passes
  #First construct a Regexp from each loaded value, which may be a Regexp or string
  #Then construct the union. Note that if the union is constructed directly from a combination of strings and Regexps then
  #it may not preserve options correctly.
  def keyword_exclusions
    @@keyword_exclusions ||= Regexp.union(load_keyword_exclusions.collect {|ex| Regexp.new(Regexp.quote(ex), Regexp::IGNORECASE)} )
  end

  def exclude_keywords(keywords)
    keywords.reject {|kw| kw.name.match(keyword_exclusions)}
  end

end