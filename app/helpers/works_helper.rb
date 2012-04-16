module WorksHelper
  def link_to_work_authors(work, limit= nil)
    if !work.name_strings.author.empty?
      authors = Array.new
      work.name_strings.author.each do |a|
        authors << "#{link_to a.name.gsub(",", ", "), name_string_path(a)}"
      end
      if limit
        if authors.size > 5
          authors = authors.first(6) << t('common.works.et_al')
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

  def skip_title_secondary(work)
    work.title_secondary.blank? or ['BookSection', 'ConferencePaper', 'ConferencePoster', 'Report'].include?(work.class.to_s)
  end

  #return a string with links to all of the creators
  def creator_links(work)
    work_name_strings_to_links(work.work_name_strings.select { |wns| wns.role == @work.creator_role })
  end

  #return an array of arrays. Each array has as its first element a contributor role and
  #as its second element an array of name strings for contributors with those roles.
  def contributors_by_role(work)
    #This gets us an ordered hash
    work.work_name_strings.select { |wns| wns.role != work.creator_role }.group_by { |wns| wns.role }
  end

  #takes an array of work name strings and gives back the html for links to the names
  def work_name_strings_to_links(work_name_strings)
    work_name_strings.collect { |wns| wns.name_string }.collect do |ns|
      link_to(h(ns.name.gsub(',', ', ')), name_string_path(ns))
    end.join('; ').html_safe
  end

  def decide_edit_partial(work)
    decide_partial(work, '')
  end

  def decide_merge_partial(work)
    decide_partial(work, '_merge')
  end

  def decide_partial(work, prefix)
    name = work.class.name.to_s.underscore
    partial = if ['.haml', ''].detect { |suffix| File.exist?("#{Rails.root}/app/views/works/forms/_form#{prefix}_#{name}.html#{suffix}") }
      name
    else
      'generic'
    end
    "works/forms/form#{prefix}_#{partial}"
  end

  def new_work_header(person)
    if person
      t('common.works.add_works_for_person_html', :person_link => link_to(person.display_name, person_path(person)))
    else
      t('common.works.add_works_html')
    end
  end

  def link_to_google_book(work)
    if !work.publication.nil? and !work.publication.isbns.blank?
      capture_haml :div, {:class => "right"} do
        haml_tag :span, {:title => ISBN.model_name.human}
        work.publication.isbns.first[:name]
        haml_tag :span, {:title => "#{ISBN.model_name.human}:#{work.publication.isbns.first[:name]}", :class =>"gbs-thumbnail gbs-link-to-preview gbs-link"}
      end
    elsif !work.publication.nil? and !work.publication.issn_isbn.blank?
      capture_haml :div, {:class => "right"} do
        haml_tag :span, {:title => ISBN.model_name.human}
        work.publication.issn_isbn
        haml_tag :span, {:title => "#{ISBN.model_name.human}:#{work.publication.issn_isbn.gsub(" ", "")}", :class =>"gbs-thumbnail gbs-link-to-preview gbs-link"}
      end
    else
      # Nothing
    end
  end

  #The self_or_x methods return the passed object if a string or the field value for :x if not.
  #The exception is self_or_field which is a general method to implement these
  #Used to simplify some of the views/works/forms/fields views
  def self_or_name(string_or_object)
    self_or_field(string_or_object, :name)
  end

  def self_or_id(string_or_object)
    self_or_field(string_or_object, :id)
  end

  def self_or_field(string_or_object, field)
    string_or_object.kind_of?(String) ? string_or_object : string_or_object.send(field)
  end

  def reorder_list_message(list_type)
    case list_type
      when "author_name_strings"
        t('common.works.update_author_list')
      when "editor_name_strings"
        t('common.works.update_editor_list')
      else
        t('common.works.update_list')
    end
  end

  def hide_publication_in_metadata(work)
    work.publication.nil? or work.publication.name.blank? or work.is_a?(BookWhole)
  end

end