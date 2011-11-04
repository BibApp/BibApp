module KeywordCloudHelper

  mattr_accessor :keyword_exclusions_regexps

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

  #TODO - it is theoretically possible to combine all of the exclusions using Regexp.union - first
  #read them from the file, then convert any that are strings using Regexp.new(Regexp.quote(string))
  #(there may be a problem with using union directly on a combination of Strings and Regexps)
  #then Regexp.union the resulting list of regexps. Then match directly against that.
  #However, this doesn't always work properly with Ruby 1.8.7. It seems more promising in 1.9.2.
  def exclude_keywords(keywords)
    keywords.reject { |kw| keyword_exclusions.detect {|exclusion| kw.name.match(exclusion) }}
  end

  def keyword_exclusions
    self.keyword_exclusions_regexps ||= create_keyword_exclusions
  end

  def create_keyword_exclusions
    raw_exclusions = load_keyword_exclusions
    raw_exclusions.collect do |exclusion|
      exclusion.is_a?(Regexp) ? exclusion : Regexp.new(Regexp.quote(exclusion), Regexp::IGNORECASE)
    end
  end

  #loads an array from the keyword_exclusions config file.
  #This list should consist of Strings and Regexps.
  def load_keyword_exclusions
    (YAML.load_file(File.join(Rails.root, 'config', 'keyword_exclusions.yml')) || []) rescue []
  end

end