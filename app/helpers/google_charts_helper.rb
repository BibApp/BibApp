module GoogleChartsHelper

  #generate the google chart URI
  #see http://code.google.com/apis/chart/docs/making_charts.html
  def google_chart_url(facets, work_count)
    chd = "chd=t:"
    chl = "chl="
    facets[:types].each_with_index do |r, i|
      perc = (r.value.to_f / work_count.to_f * 100).round.to_s
      chd += "#{perc},"
      ref = r.name.to_s == 'BookWhole' ? 'Book' : r.name.to_s
      chl += "#{ref.titleize.pluralize}|"
    end
    chd = chd[0...(chd.length-1)]
    chl = chl[0...(chl.length-1)]
    "http://chart.apis.google.com/chart?cht=p&chco=346090&chs=350x100&#{chd}&#{chl}"
  end

end
