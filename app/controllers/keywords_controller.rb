class KeywordsController < ApplicationController
  include GoogleChartsHelper
  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy]

  make_resourceful do
    build :all
  end

  def timeline

    @current_object = Group.find(params[:group_id]) if params[:group_id]
    @current_object = Person.find(params[:person_id]) if params[:person_id]

    search(params)

    @year_keywords = Array.new
    @chart_urls = Array.new
    @work_counts = Array.new
    @years = Array.new

    facet_years = @facets[:years].compact
    year_array = facet_years.empty? ? [] : Range.new(facet_years.first.name, facet_years.last.name).to_a

    year_array.each do |y|
      year_data = KeywordsHelper::YearTag.new(:year => y, :tags => Array.new)

      params[:fq] = %Q(year_facet:"#{y}")
      search(params)

      work_count = @q.data['response']['numFound']
      next if work_count == 0

      @work_counts << work_count
      @years << y

      @chart_urls << google_chart_url(@facets, work_count)

      add_tags(year_data, @facets[:keywords], y)
      @year_keywords << year_data unless year_data.tags.blank?
    end

  end

  protected

  def add_tags(year_data, all_keywords, year)
    #generate normalized keyword list
    max = 25
    bin_count = 5
    used_keywords = all_keywords.first(max)

    if used_keywords.blank?
      yt = KeywordsHelper::TagDatum.new(:name => nil, :count => nil, :bin => 3, :year => year)
      year_data.tags << yt
    else
      max_kw_freq = [used_keywords[0].value.to_i, bin_count].max

      used_keywords.sort { |a, b| a.name <=> b.name }.each do |kw|
        tag = KeywordsHelper::TagDatum.new(:name => kw.name, :count => kw.value, :year => year)
        tag.bin = ((tag.count.to_f * bin_count.to_f) / max_kw_freq).ceil
        year_data.tags << tag
      end
    end
  end

end
