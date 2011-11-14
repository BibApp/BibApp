require 'lib/open_url_book_context'
class BookWhole < Work
  include OpenUrlBookContext

  def self.roles
    ['Author', 'Editor', 'Translator', 'Illustrator']
  end

  def self.creator_role
    'Author'
  end

  def self.contributor_role
    'Editor'
  end

  def type_uri
    "http://purl.org/eprint/type/Book"
  end

  def open_url_kevs
    open_url_kevs = Hash.new
    open_url_kevs[:format] = "&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Abook"
    open_url_kevs[:genre] = "&rft.genre=book"
    open_url_kevs[:title] = "&rft.btitle=#{CGI.escape(self.title_primary)}"
    open_url_kevs[:publisher] = "&rft.pub=#{self.publisher.authority.name}"
    unless self.publication.nil?
      open_url_kevs[:isbn] = "&rft.isbn=#{self.publication.isbns.first[:name]}" if !self.publication.isbns.empty?
    end
    open_url_kevs[:date] = "&rft.date=#{self.publication_date_string}"

    return open_url_kevs
  end

  def append_apa_work_type_specific_text!(citation_string)
    citation_string << self.publisher.authority.name if self.publisher
    #Only add a period if the string doesn't currently end in a period.
    citation_string << ". " if !citation_string.match("\.\s*\Z")
  end
end