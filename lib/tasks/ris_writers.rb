class RISWriter < Object
  attr_accessor :work, :file

  def initialize(work)
    self.work = work
  end

  def write_to_file(filename)
    File.open(filename, 'w') do |f|
      self.file = f
      write_type
      write_titles
      write_authors
      write_keywords
      write_links
      write_dates
      write_language
      write_abstract_and_notes
      write_volume
      write_publication_info
      write_special
      write_identifier
      write_pages
      write_end
    end
  end

  def write_type
    write_tag(:ty, self.type)
  end

  def type
    raise RuntimeError, 'Subclass Responsiblity'
  end

  def write_special
    #for any special things for a specific writer class that are not overrides of a standard write method
    #the base method does nothing
  end

  def write_identifier
    write_tag(:sn, work.publication.try(:issn_isbn))
  end

  def write_publication_info
    write_tag(:pb, work.publisher.try(:name))
    write_tag(:op, work.publication.try(:name))
    write_tag(:cy, work.publication_place)
  end

  def write_volume
    write_tag(:vl, work.volume)
    write_tag(:is, work.issue)
  end

  def write_abstract_and_notes
    write_tag(:ab, work.abstract)
    if work.notes.present?
      notes = work.notes.strip.match(/^---/) ? YAML.load(work.notes) : work.notes
      begin
        Array.wrap(notes).each do |note|
          #some of these are probably RIS tags themselves - if we can easily detect it, use that information
          if note.match(/^\w\w: [\w\s]+$/)
            tag, value = note.split(': ')
            write_tag(tag, value)
          else
            write_tag(:n1, note)
          end
        end
      rescue Exception
        write_tag(:n1, work.notes)
      end
    end
  end

  def write_titles
    [work.title_primary, work.title_secondary, work.title_tertiary].each do |title|
      write_tag(:ti, title)
    end
  end

  def write_pages
    #by default do nothing - this varies so much that I think it should be up to the subclass
  end

  def write_authors
    work.work_name_strings.all.each do |work_name_string|
      tag = case work_name_string.role
        when 'Author', 'Creator', 'Director', 'Patent Owner' then
          :au
        when 'Editor', 'Editorial Board Member' then
          :a2
        when 'Producer' then
          :a3
        else
          raise RuntimeError, "Unrecognized role #{work_name_string.role}"
      end
      write_tag(tag, work_name_string.name_string.name)
    end
  end

  def write_keywords
    work.keywords.each do |keyword|
      write_tag(:kw, keyword.name)
    end
  end

  def write_links
    links = work.links
    return unless links.present?
    links = links.match(/^---/) ? YAML.load(links) : [links]
    links.each do |link|
      case link
        when /^(http)|(www)/
          write_tag(:ur, link)
        when /^\s?(doi:\s*)?(DOI:\s*)?10\./
          write_tag(:do, link)
        else
          puts "Cannot process link: #{link}. Skipping"
      end
    end
  rescue Exception => e
    #silently fail
  end

  def write_dates
    write_tag(:py, work.publication_date_year) if work.publication_date_year
    date_info = [work.publication_date_year, work.publication_date_month, work.publication_date_day]
    if date_info.compact.present?
      date_string = date_info.collect { |x| (x || '').to_s }.collect { |x| x.length == 1 ? "0#{x}" : x }.join('/')
      date_string = date_string + "/#{work.date_range}" if work.date_range.present?
      date_string.gsub!(/(\/)+$/, '')
      write_tag(:da, date_string)
    end
  end

  def write_language
    write_tag(:la, work.language)
  end

  def write_end
    write_tag(:er, '', false)
  end

  protected

  def generic_write_pages(tag)
    page_array = [work.start_page, work.end_page].select { |p| p.present? }.collect { |p| p.strip }.uniq
    if page_array.length == 1
      write_tag(tag, page_array.first)
    elsif page_array.length == 2
      if integer_page?(page_array.first)
        write_tag(tag, page_array.join('-'))
      else
        write_tag(tag, page_array.join(', '))
      end
    end
  end

  def integer_page?(string)
    string.to_i.to_s == string
  end

  def write_tag(tag, content, skip_blank_content = true)
    return if skip_blank_content and content.blank?
    file << "#{tag.to_s.upcase}  - #{content.to_s.strip}\r\n"
  end

end

class RISBook < RISWriter
  def type
    'BOOK'
  end

  def write_pages
    generic_write_pages(:se)
    if integer_page?(work.start_page) and integer_page?(work.end_page)
      count = work.end_page.to_i - work.start_page.to_i + 1
      write_tag(:sp, count) if count > 0
    end
  end
end

class RISJournal < RISWriter
  def write_pages
    write_tag(:m2, work.start_page)
    generic_write_pages(:sp)
  end
end

class RISJournalArticle < RISJournal
  def type
    'JOUR'
  end

end

class RISJournalWhole < RISJournal
  def type
    'JFULL'
  end
end

class RISReport < RISWriter
  def type
    'RPRT'
  end

  def write_pages
    generic_write_pages(:sp)
  end

  def write_publication_info
    super
    write_tag(:pb, work.sponsor)
  end
end

class RISGeneric < RISWriter
  def type
    'GEN'
  end
end

class RISBookSection < RISWriter
  def type
    'CHAP'
  end

  def write_pages
    generic_write_pages(:sp)
  end
end

class RISConference < RISWriter
  def write_pages
    generic_write_pages(:sp)
  end
end

class RISConferencePaper < RISConference;
  def type
    'CPAPER'
  end
end
class RISConferenceProceedingWhole < RISConference;
  def type
    'CONF'
  end
end

class RISWebPage < RISWriter
  def type
    'ELEC'
  end
end

class RISMovingImage < RISWriter
  def type
    'MPCT'
  end
end

class RISPatent < RISWriter
  def type
    'PAT'
  end

  def write_pages
    generic_write_pages(:sp)
  end

  #patents use these fields for the application number and patent number
  def write_volume
    write_tag(:m1, work.volume)
    write_tag(:sn, work.issue)
  end
end