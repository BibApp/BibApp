module WorksHelper
  def link_to_work_authors(work, limit= nil)
    if !work.name_strings.author.empty?
      authors = Array.new
      work.name_strings.author.each do |a|
        authors << "#{link_to a.name.gsub(",", ", "), name_string_path(a)}"
      end
      if limit
        if authors.size > 5
          authors = authors.first(6) << "et al."
        end
      end
      authors.join(", ")
    end
  end

  #heuristic attempt to get best results here
  #We split the string of links on newlines or semicolons
  #Then we throw away everything until the first alphanumeric character
  #Then we throw away everything including and after the first whitespace character
  #This should preserve anything that is actually a good link, e.g. http://whatever.com, 10.1000/doistuff,
  #www.urlwithoutprotocal.com, etc. while solving some common problem cases.
  #Another method will be tasked with determining what these actually are (or may be) and trying to link them
  #appropriately.
  def split_potential_links(work)
    work.links.split(/[\n;]+/).collect { |l| l.sub(/^\W+/, '').sub(/\s.*$/, '') }
  end

  #We try to make a reasonable link if 'link' looks like something linkable. Otherwise just return it unchanged.
  #It might be desirable to try to link to things like 'www.example.com/some/path', but it's not actually easy to figure
  #out the difference between that and 'somerandomtext' in general.
  def link_potential_link(link)
    return link_to(link, link) if looks_like_url(link)
    return link_to(link, doi_link(link)) if looks_like_doi(link)
    link
  end

  #very crude check for linkable url
  def looks_like_url(link)
    link.match(/^http/)
  end

  #crude check for doi
  def looks_like_doi(link)
    link.match(/^10\.\w+\/\S+/)
  end

  def doi_link(link)
    "http://dx.doi.org/#{CGI.escape(link)}"
  end

  def work_class(work)
    work.class.name.to_s
  end

  def normalized_work_class(work)
    type = work_class(work)
    if ['.haml', ''].detect { |ext| File.exist?("#{Rails.root}/app/views/works/apa/_#{type.underscore}.html#{ext}") }
      type
    else
      'generic'
    end
  end

  def tag_filter(tag)
    %Q(tags: "#{tag.name}")
  end

  #helpers for metadata views
  def location_label(work)
    if work.class == PresentationLecture
      "Location Given"
    else
      "Conference Location"
    end
  end

  def publication_place_label(work)
    case work.class.to_s
      when 'ConferencePaper', 'ConferencePoster', 'ConferenceProceeding', 'PresentationLecture', 'Artwork', 'Exhibition', 'Performance', 'RecordingSound'
        'Location'
      else
        "Publication Place"
    end
  end

  def date_range_label(work)
    case work.class.to_s
      when 'Patent'
        "Filing Date"
      when 'WebPage'
        "Date of Last Visit"
      when 'Exhibition'
        "Exhibition Dates"
      when 'Performance'
        "Performance Date"
      when 'JournalWhole'
        "Dates"
      when 'ConferencePaper', 'ConferencePoster', 'ConferenceProceedingWhole', 'PresentationLecture'
        "Conference Dates"
      else
        'Date Range'
    end
  end

  def end_page_label(work)
    case work.class.to_s
      when 'BookWhole', 'Monograph', 'ConferenceProceedingWhole', 'DissertationThesis'
        "Total Pages"
      else
        'End Page'
    end
  end

  def issue_label(work)
    case work.class.to_s
      when 'Report'
        'Series Number'
      else
        'Issue'
    end
  end

  def publication_date_label(work)
    case work.class.to_s
      when 'ConferencePoster'
        "Date Presented"
      when 'PresentationLecture'
        "Date Given"
      when 'Artwork'
        "Date of Composition"
      when 'DissertationThesis'
        "Degree Date"
      when 'Patent', 'RecordingMovingImage'
        "Date Issued"
      else
        'Date Published'
    end
  end

  def issn_isbn_label(work)
    case work.class.to_s
      when 'JournalArticle', 'JournalWhole', 'BookReview'
        "ISSN"
      when 'RecordingSound', 'RecordingMovingImage'
        "ISRC"
      else
        'ISBN'
    end
  end

  def publication_label(work)
    case work.class.to_s
      when 'BookSection'
        "Book Title"
      when 'JournalArticle', 'BookReview'
        "Journal Title"
      when 'ConferencePaper', 'ConferencePoster'
        "Conference Title"
      when 'PresentationLecture'
        "Title of Conference or Occasion"
      when 'Performance', 'RecordingSound', 'RecordingMovingImage'
        "Title of Larger Work"
      when 'Report'
        "Series Title"
      else
        'Publication Title'
    end
  end

  def publisher_label(work)
    case work.class.to_s
      when 'Artwork'
        "Institution or Collection Name"
      when 'DissertationThesis'
        "Degree Granting Institution"
      when 'Exhibition', 'Performance'
        "Venue"
      when 'RecordingSound'
        "Recording Label"
      when 'RecordingMovingImage'
        "Production Company"
      when 'Grant'
        "Institution"
      else
        'Publisher'
    end
  end

  def title_primary_label(work)
    case @work.class.to_s
      when 'BookSection'
        "Article/Chapter Title"
      when 'JournalArticle'
        "Article Title"
      else
        'Title'
    end
  end

  def skip_title_secondary(work)
    work.title_secondary.blank? or ['BookSection', 'ConferencePaper', 'ConferencePoster', 'Report'].include?(work.class.to_s)
  end

  #return a string with links to all of the creators
  def creator_links(work)
    @work.work_name_strings.select { |wns| wns.role == @work.creator_role }.collect do |wns|
      wns.name_string
    end.collect do |ns|
      link_to(h(ns.name.gsub(',', ', ')), name_string_path(ns))
    end.join(', ').html_safe
  end
  
end