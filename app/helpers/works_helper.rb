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
    work.links.split(/[\n;]+/).collect {|l| l.sub(/^\W+/, '').sub(/\s.*$/, '') }
  end

  def link_potential_link(link)
    link
  end

end
