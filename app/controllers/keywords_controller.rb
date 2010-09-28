class KeywordsController < ApplicationController
  
  #Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [ :new, :create, :edit, :update, :destroy ]
  
  make_resourceful do
    build :none

  end

  caches_page :timeline

  def timeline

    @current_object = Group.find(params[:group_id]) if params[:group_id]
    @current_object = Person.find(params[:person_id]) if params[:person_id]

    search(params)

    first_year = @facets[:years].first.nil? ? nil : @facets[:years].first.name
    last_year = @facets[:years].last.nil? ? nil : @facets[:years].last.name
    years_with_papers = Range.new(first_year, last_year)
    # Ensure we have an array; we'll need this to get the list of years
    if years_with_papers.is_a?(Enumerable)
      year_arr = years_with_papers.to_a
    else
      year_arr = [years_with_papers]
    end

    @year_keywords = Array.new
    @chart_urls = Array.new
    @work_counts = Array.new
    @years = Array.new

    year_arr.each do |y|
      ydata = KeywordsHelper::YearTag.new
      ydata.year = y
      ydata.tags = Array.new

      params[:fq] = "year_facet:\"#{y}\""
      search(params)

      work_count = @q.data['response']['numFound']

      next if work_count == 0
      
      @work_counts << work_count
      @years << y

      #generate the google chart URI
      #see http://code.google.com/apis/chart/docs/making_charts.html
      #
      chd = "chd=t:"
      chl = "chl="
      chdl = "chdl="
      chdlp = "chdlp=b|"
      @facets[:types].each_with_index do |r,i|
        perc = (r.value.to_f/work_count.to_f*100).round.to_s
        chd += "#{perc},"
        ref = r.name.to_s == 'BookWhole' ? 'Book' : r.name.to_s
        chl += "#{ref.titleize.pluralize}(#{r.value})|"
        chdl += "#{perc}% #{ref.titleize.pluralize}|"
        chdlp += "#{i.to_s},"
      end
      chd = chd[0...(chd.length-1)]
      chl = chl[0...(chl.length-1)]
      chdl = chdl[0...(chdl.length-1)]
      chdlp = chdlp[0...(chdlp.length-1)]

      if chd.nil? or chl.nil?
        @chart_urls << "#"
      else
        @chart_urls << "http://chart.apis.google.com/chart?cht=p&chco=346090&chs=350x100&#{chd}&#{chl}"
      end

      #generate normalized keyword list
      max = 25
      bin_count = 5
      kwords = @facets[:keywords].first(max)

      if kwords.blank?
          yt = KeywordsHelper::TagDatum.new(Struct.new(:name, :count, :year).new(nil,nil,y))
          yt.bin = 3
          yt.year = y
          ydata.tags << yt
      else
        max_kw_freq = kwords[0].value.to_i > bin_count ? kwords[0].value.to_i : bin_count

        @keywords = kwords.map { |kw|
          s = Struct.new(:name, :count, :year)
          s.new(kw.name, kw.value, y)
        }.sort { |a, b| a.name <=> b.name }

        @keywords.each do |kw|
          yt = KeywordsHelper::TagDatum.new(kw)
          yt.bin = ((kw.count.to_f * bin_count.to_f)/max_kw_freq).ceil
          yt.year = y
          ydata.tags << yt
        end
      end
      @year_keywords << ydata unless ydata.tags.blank?
    end



#    @all_tags = @year_tags.collect do |yeardata|
#      yeardata.tags.collect {|t|
#        t.name
#      }
#    end.flatten.uniq.sort
  end
  
end
