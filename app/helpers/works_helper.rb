require 'rest_client'

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

  #To get around the fact that we're on https we don't use the gbs javascript library, we query google here and
  #construct the result directly.
  #TODO An alternate and possibly better way would be to do this in javascript if possible - do the query
  #below in javascript (should be okay since it is https?) then construct the bit of the view instead of in the partial.
  #Alternately, have a callback to the server instead of doing this while constructing the main page.
  def link_to_google_book(work_or_isbn)
    if work_or_isbn.is_a?(Work)
      return unless work_or_isbn.publication.present?
      isbn = if work_or_isbn.publication.isbns.first.present?
        work_or_isbn.publication.isbns.first[:name]
      elsif work_or_isbn.publication.issn_isbn.present?
        work_or_isbn.publication.issn_isbn.gsub(' ', '')
      else
        nil
      end
    else
      isbn = work_or_isbn.gsub(' ', '')
    end
    return unless isbn
    google_response = RestClient.get('https://www.googleapis.com/books/v1/volumes', :params => {:q => "isbn:#{isbn}"})
    json = JSON.parse(google_response)
    volume_info = json['items'][0]['volumeInfo']
    return {:link => volume_info['previewLink'], :image => volume_info['imageLinks']['smallThumbnail']}
  rescue Exception => e
    return
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