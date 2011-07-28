module KeywordCloudHelper
  def set_keywords(facets)
    if facets[:keywords].present?
      max = 10
      bin_count = 5
      kwords = facets[:keywords].first(max)
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

end