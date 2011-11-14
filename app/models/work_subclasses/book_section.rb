require 'lib/open_url_book_context'
class BookSection < Work
  include OpenUrlBookContext

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
    "http://purl.org/eprint/type/BookItem"
  end

  def open_url_kevs
    open_url_kevs = Hash.new
    open_url_kevs[:format] = "&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Abook"
    open_url_kevs[:genre] = "&rft.genre=bookitem"
    open_url_kevs[:title] = "&rft.title=#{CGI.escape(self.title_primary)}"
    unless self.publisher.nil?
      open_url_kevs[:publisher] = "&rft.pub=#{self.publisher.authority.name}"
    end
    unless self.publication.nil?
      open_url_kevs[:isbn] = "&rft.isbn=#{self.publication.isbns.first[:name]}" if !self.publication.isbns.empty?
    end
    open_url_kevs[:date] = "&rft.date=#{self.publication_date_string}"

    return open_url_kevs
  end

end