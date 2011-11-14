require 'lib/open_url_conference_context'
class ConferencePaper < Work
  include OpenUrlConferenceContext

  def self.roles
    ['Author', 'Editor']
  end

  def self.creator_role
    'Author'
  end

  def self.contributor_role
    'Editor'
  end

  def type_uri
    "http://purl.org/eprint/type/ConferencePaper"
  end

  def open_url_kevs
    open_url_kevs = Hash.new
    open_url_kevs[:format] = "&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Abook"
    open_url_kevs[:genre] = "&rft.genre=proceeding"
    open_url_kevs[:title] = "&rft.title=#{CGI.escape(self.title_primary)}"
    unless self.publication.nil?
      open_url_kevs[:source] = "&rft.jtitle=#{CGI.escape(self.publication.authority.name)}"
      open_url_kevs[:issn] = "&rft.issn=#{self.publication.issns.first[:name]}" if !self.publication.issns.empty?
      open_url_kevs[:isbn] = "&rft.isbn=#{self.publication.isbns.first[:name]}" if !self.publication.isbns.empty?
    end
    open_url_kevs[:date] = "&rft.date=#{self.publication_date_string}"
    open_url_kevs[:volume] = "&rft.volume=#{self.volume}"
    open_url_kevs[:issue] = "&rft.issue=#{self.issue}"
    open_url_kevs[:start_page] = "&rft.spage=#{self.start_page}"
    open_url_kevs[:end_page] = "&rft.epage=#{self.end_page}"

    return open_url_kevs
  end

  def append_apa_work_type_specific_text!(citation_string)
    citation_string << "In #{self.title_secondary}" if self.title_secondary
    citation_string << ": Vol. #{self.volume}" if self.volume
    #Only add a period if the string doesn't currently end in a period.
    citation_string << ". " if !citation_string.match("\.\s*\Z")
    citation_string << "#{self.publication.authority.name}" if self.publication
    citation_string << ", (" if self.start_page or self.end_page
    citation_string << self.start_page if self.start_page
    citation_string << "-#{self.end_page}" if self.end_page
    citation_string << ")" if self.start_page or self.end_page
    citation_string << "." if !citation_string.match("\.\s*\Z")
    citation_string << self.publisher.authority.name if self.publisher
    citation_string << "."
  end

end