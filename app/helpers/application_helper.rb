# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  require 'namecase'
  
  def link_to_login_or_admin
    if current_user
      link_to_unless_current "Admin", :controller => :admin, :action => :index
    else
      link_to_unless_current "Log in", :controller => :account, :action => :login
    end
  end
  
  def person_name_link(is_current, person)
    link_to_unless( is_current,
      "<span class=\"given-name\">#{h(person.first_name)}</span> <span class=\"family-name\">#{h(person.last_name)}</span>",
      person_path(person) 
    )
  end

  def namecase(name)
    NameCase.new(name).nc!
  end
    
  # TODO: extract lower... add support for other popular reftypes (ordered by importance)
  # Journal Article
  # Conference Proceeding
  # Book, Section
  # Report
  # Book, Whole
  # Dissertation / Thesis
  
  def format_citation_apa_to_html(citation)
    apa = nil
    apa =  '<span class="person_group"><span class="authors">' + author_format(citation) + '</span></span> '
    apa += '(<span class="year">' + citation.pub_year.to_s + '</span>). '
    apa += '<span class="article-title">' + citation.title_primary.titleize + '</span>. '
    if citation.reftype_id == 5 # Conference Proceeding
      apa += 'In ' + citation.title_secondary.titleize + ',' if citation.title_secondary
      apa += '<span class="volume">' + citation.volume + '</span>' if citation.volume && !citation.volume.empty?
      apa += '(<span class="issue">' + citation.issue + '</span>)' if citation.issue && !citation.issue.empty?
      apa += ', ' + citation.start_page + '-' if citation.start_page && !citation.start_page.empty?
      apa += citation.end_page + '.' if citation.end_page && !citation.end_page.empty?
      apa += citation.place_of_publication + ': ' if citation.place_of_publication && !citation.place_of_publication.empty?
      apa += citation.publisher + '.' if citation.publisher && !citation.publisher.empty?
    elsif citation.reftype_id == 4 # Book, Section
      apa += 'In <span class="source">' + citation.periodical_full.titleize + '</span>, ' if citation.periodical_full && !citation.periodical_full.empty?
      apa += '<span class="volume">' + citation.volume + '</span>' if citation.volume && !citation.volume.empty?
      apa += '<span class="issue">' + citation.issue + '</span>)' if citation.issue && !citation.issue.empty?
      apa += '(' + citation.start_page + '-' if citation.start_page && !citation.start_page.empty?
      apa += citation.end_page + '). ' if citation.end_page && !citation.end_page.empty?
      apa += citation.place_of_publication + ': ' if citation.place_of_publication && !citation.place_of_publication.empty?
      apa += citation.publisher + '.' if citation.publisher && !citation.publisher.empty?
    elsif citation.reftype_id == 3 # Book, Whole
      apa += citation.place_of_publication + ': ' if citation.place_of_publication && !citation.place_of_publication.empty?
      apa += citation.publisher + '.' if citation.publisher && !citation.publisher.empty?
    elsif citation.reftype_id == 1 # Journal Article
      apa += '<span class="source">' + citation.periodical_full.titleize + '</span>, ' if citation.periodical_full && !citation.periodical_full.empty?
      apa += '<span class="volume">' + citation.volume + '</span>' if citation.volume && !citation.volume.empty?
      apa += '(<span class="issue">' + citation.issue + '</span>)' if citation.issue && !citation.issue.empty?
      apa += ', ' + citation.start_page + '-' if citation.start_page && !citation.start_page.empty?
      apa += citation.end_page + '.' if citation.end_page && !citation.end_page.empty?
    end
    apa
  end

  # Used by DSpace batch importer
  def format_citation_apa_to_s(citation)
    apa = nil
    if citation.reftype_id == 5
      apa = "#{author_format(citation)} (#{citation.pub_year}). #{citation.title_primary}. In #{citation.title_secondary}, #{citation.volume}"
      apa +=  " (#{citation.issue})" if citation.issue && !citation.issue.empty?
      apa += ", #{citation.start_page}-#{citation.end_page}."
    elsif citation.reftype_id == 1
      apa =  author_format(citation) + ' '
      apa += '(' + citation.pub_year.to_s + '). ' if citation.pub_year
      apa += citation.title_primary.titleize + '. ' if citation.title_primary && !citation.title_primary.empty?
      apa += citation.periodical_full.titleize + ', ' if citation.periodical_full && !citation.periodical_full.empty?
      apa += citation.volume if citation.volume
      apa += '(' + citation.issue + ')' if citation.issue
      apa += ', ' + citation.start_page + '-' if citation.start_page
      apa += citation.end_page + '.'
    end
    apa
  end

  # TODO: Rename to format_authors
  def author_format(citation)
     # determine author_string size
     # if size > 6
     citation.authors ||= ""
     author_array = citation.authors.split(/\|/)
     if author_array.size > 6
       append = ', et al.'
     else
       append = ""
     end
   
     author_string = author_array.slice(0...6).join(", ")       
     author_string = author_string.gsub(/(\w+,)(\w+)/, '\1 \2')

     if author_array.size > 6
       author_string = author_string.gsub(/, ([\w\s]+)(, [\w\. ]+)\z/, ', \1\2')
     else
       author_string = author_string.gsub(/, ([\w\s]+)(, [\w\. ]+)\z/, ', & \1\2')
     end

     # truncates hyphenated first names to initials
     while author_string =~ /, (\w+)-(\w+)/
       first_part = $1
       second_part = $2
       first_initial = first_part.slice(0,1)
       second_initial = second_part.slice(0,1)
       author_string = author_string.sub(/, (\w+)-(\w+)/, ", #{first_initial}.#{second_initial}.")
     end

     while author_string =~ /and (\w+, )(\w{2,}),?/
      name = $2
      initial = name.slice(0,1)
      author_string = author_string.sub($2, " #{initial}.,")
     end

     # truncates one-word first names to initials
     while author_string =~ /(\w+, )(\w{2,})[\.,]/
      name = $2
      initial = name.slice(0,1)
      author_string = author_string.sub($2, " #{initial}.,")
     end

     author_string = author_string.gsub(/,,/, ',')

     # corrects case of all-caps names
     while author_string =~ /([A-Z]{2,})/
       corrected_name = $1.capitalize!
       author_string = author_string.sub($1, "#{corrected_name}")
     end

     # deletes potential comma after last author name
     author_string = author_string.gsub(/,\z/, '')

     # cleans up goofy multiple-initial formatting
     author_string = author_string.gsub(/([A-Z]\.), ([A-Z]\.)/, '\1\2') 

     # [last name], [first name] [middle initial]." -> "[last name], [first initial]. [middle initial]."
     while author_string =~ /(\w{2,}), (\w{2,}) ([A-Z]\.)/ || author_string =~ /(\w{2,}), (\w{2,})\z/
      first_name = $2
      first_initial = first_name.slice(0,1)
      author_string = author_string.sub($2, "#{first_initial}.")
     end

     # changes names with format "[full first name], [full last name]" to APA format
     while author_string =~ (/(\w{2,}), (\w{2,})/)
       first_name = $1
       last_name = $2
       initial = first_name.slice(0,1)
       author_string = author_string.sub(/(\w{2,}), (\w{2,})/, "#{last_name}, #{initial}.")
     end

     # one last correction for names that are still in "[initials], [last name]" format
     while author_string =~ /([A-Z]\.[A-Z]\.?) (\w+)/
       initials = $1
       last_name = $2
       author_string = author_string.sub(/([A-Z]\.){1,2} (\w+)/, "#{last_name}, #{initials}")
     end

    author_string = author_string + append
    author_string = author_string
  end
  
  def random_image
    image_files = %w( .jpg .gif .png )
    files = Dir.entries(
          "#{RAILS_ROOT}/public/images/rotate" 
      ).delete_if { |x| !image_files.index(x[-4,4]) }
    files[rand(files.length)]
  end
  
  def tag_cloud(tags, classes)
    max, min = 0, 0
    tags.each { |t|
      max = t.count.to_i if t.count.to_i > max
      min = t.count.to_i if t.count.to_i < min
    }

    divisor = ((max - min) / classes.size) + 1

    tags.each { |t|
      yield t.name, classes[(t.count.to_i - min) / divisor]
    }
  end
  
  def link_to_resolver(text, citation, resolver_url)
    suffix="ctx_enc=info%3Aofi%2Fenc%3AUTF-8&amp;ctx_id=10_1&amp;ctx_tim=2006-5-11T13%3A11%3A1CDT&amp;ctx_ver=Z39.88-2004&amp;res_id=http%3A%2F%2Fsfx.wisconsin.edu%2Fwisc&amp;rft.atitle=#{citation.title_primary.to_s.sub(" ", "+")}&amp;rft.date=#{citation.pub_year.to_s}&amp;rft.issn=#{citation.issn_isbn}&amp;rft.issue=#{citation.issue.to_s}&amp;rft.volume=#{citation.volume.to_s}&amp;rft.spage=#{citation.start_page}"
    link_to text, "#{resolver_url}?#{suffix}"
  end
  
  def link_to_findit(citation)
    link_to_resolver("Find it", citation, 'http://sfx.wisconsin.edu/wisc')
  end

  def to_dspace_xml(citation)
    builder = Builder::XmlMarkup.new(:indent => 2)
    xml = builder.dublin_core { |dc|
      dc.dcvalue(citation.title_primary, :element => "title", :qualifier => "none") if citation.title_primary and !citation.title_primary.empty?
      dc.dcvalue(citation.abstract, :element => "description", :qualifier => "abstract") if citation.abstract and !citation.abstract.empty?
      dc.dcvalue(citation.pub_year, :element => "date", :qualifier => "issued")
      dc.dcvalue(citation.publisher, :element => "publisher", :qualifier => "none") if citation.publisher and !citation.publisher.empty?
      dc << copyright_statement(citation)
      dc << citation.publication.publisher.dspace_xml
      dc.dcvalue("This material is presented to ensure timely dissemination of scholarly and technical work. Copyright and all rights therein are retained by authors or by other copyright holders. All persons copying this information are expected to adhere to the terms and constraints invoked by each author's copyright. In most cases, these works may not be reposted without the explicit permission of the copyright holder.", :element => "description", :qualifier => "none")
      dc.dcvalue(format_citation_apa_to_s(citation), :element => "identifier", :qualifier => "citation")
      dc.dcvalue("application/pdf", :element => "format", :qualifier => "mimetype")
      citation.author_array.each do |a|
        dc.dcvalue(a, :element => "contributor", :qualifier => "author")
      end
    }
    xml
  end

  private
  def authors_dspace
    author_array.map { |a| "<dcvalue element=\"contributor\" qualifier=\"author\">#{a}</dcvalue>" }.join("\n")
  end
end
