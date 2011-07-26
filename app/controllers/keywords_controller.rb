class KeywordsController < ApplicationController

  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy]

  make_resourceful do
    build :all
  end

  def timeline

    @current_object = Group.find(params[:group_id]) if params[:group_id]
    @current_object = Person.find(params[:person_id]) if params[:person_id]

    search(params)

    facet_years = @facets[:years].compact
    if facet_years.empty?
      year_arr = []
    else
      first_year = facet_years.first.name
      last_year = facet_years.last.name
      year_arr = Range.new(first_year, last_year).to_a
    end

    @year_keywords = Array.new
    @chart_urls = Array.new
    @work_counts = Array.new
    @years = Array.new

    year_arr.each do |y|
      year_data = KeywordsHelper::YearTag.new
      year_data.year = y
      year_data.tags = Array.new

      params[:fq] = "year_facet:\"#{y}\""
      search(params)

      work_count = @q.data['response']['numFound']
      next if work_count == 0

      @work_counts << work_count
      @years << y

      @chart_urls << google_chart_url(work_count, @facets[:types])

      add_tags(year_data, @facets[:keywords])
      @year_keywords << year_data unless year_data.tags.blank?
    end

  end

  protected

  def add_tags(year_data, all_keywords)
    #generate normalized keyword list
    max = 25
    bin_count = 5
    used_keywords = all_keywords.first(max)

    if used_keywords.blank?
      yt = KeywordsHelper::TagDatum.new(Struct.new(:name, :count, :year).new(nil, nil, y))
      yt.bin = 3
      yt.year = y
      year_data.tags << yt
    else
      max_kw_freq = used_keywords[0].value.to_i > bin_count ? used_keywords[0].value.to_i : bin_count

      keyword_array = used_keywords.map { |kw|
        s = Struct.new(:name, :count, :year)
        s.new(kw.name, kw.value, y)
      }.sort { |a, b| a.name <=> b.name }

      keyword_array.each do |kw|
        yt = KeywordsHelper::TagDatum.new(kw)
        yt.bin = ((kw.count.to_f * bin_count.to_f)/max_kw_freq).ceil
        yt.year = y
        year_data.tags << yt
      end
    end
  end

  #generate the google chart URI
  #see http://code.google.com/apis/chart/docs/making_charts.html
  def google_chart_url(work_count, types)
    chd = "chd=t:"
    chl = "chl="
    types.each_with_index do |r, i|
      perc = (r.value.to_f/work_count.to_f*100).round.to_s
      chd += "#{perc},"
      ref = r.name.to_s == 'BookWhole' ? 'Book' : r.name.to_s
      chl += "#{ref.titleize.pluralize}(#{r.value})|"
    end
    chd = chd[0...(chd.length-1)]
    chl = chl[0...(chl.length-1)]

    if chd and chl
      "http://chart.apis.google.com/chart?cht=p&chco=346090&chs=350x100&#{chd}&#{chl}"
    else
      "#"
    end
  end

end
