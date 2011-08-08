class JournalArticle < Work
  validates_presence_of :title_primary

  def self.roles
    ['Author']
  end

  def self.creator_role
    'Author'
  end

  def self.contributor_role
    'Author'
  end

  def type_uri
    "http://purl.org/eprint/type/JournalArticle"
  end

  def open_url_kevs
    open_url_kevs = Hash.new
    open_url_kevs[:format] = "&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal"
    open_url_kevs[:genre] = "&rft.genre=article"
    open_url_kevs[:title] = "&rft.atitle=#{CGI.escape(self.title_primary)}"
    unless self.publication.nil?
      open_url_kevs[:source] = "&rft.jtitle=#{CGI.escape(self.publication.authority.name)}"
      open_url_kevs[:issn] = "&rft.issn=#{self.publication.issns.first[:name]}" if !self.publication.issns.empty?
    end
    open_url_kevs[:date] = "&rft.date=#{self.publication_date}"
    open_url_kevs[:volume] = "&rft.volume=#{self.volume}"
    open_url_kevs[:issue] = "&rft.issue=#{self.issue}"
    open_url_kevs[:start_page] = "&rft.spage=#{self.start_page}"
    open_url_kevs[:end_page] = "&rft.epage=#{self.end_page}"

    return open_url_kevs
  end

  def open_url_context_hash
    self.open_url_base_context_hash.merge(
        'rft_val_fmt' => 'info:ofi/fmt:kev:mtx:journal',
        'rft.genre' => 'article',
        'rft.atitle' => self.title_primary,
        'rft.jtitle' => (self.publication.authority.name rescue nil),
        'rft.volume' => self.volume,
        'rft.issue' => self.issue,
        'rft.spage' => self.start_page,
        'rft.date' => self.publication_date.try(:year),
        'rft.issn' => (self.publication.authority.issn_isbn rescue nil),
        'rft.aulast' => self.name_strings.first.last_name
    )
  end

end
