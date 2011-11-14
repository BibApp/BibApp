class JournalArticle < Work

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

  def open_url_context_hash
    self.open_url_base_context_hash.merge(
        'rft_val_fmt' => 'info:ofi/fmt:kev:mtx:journal',
        'rft.genre' => 'article',
        'rft.atitle' => self.title_primary,
        'rft.jtitle' => (self.publication.authority.name rescue nil),
        'rft.volume' => self.volume,
        'rft.issue' => self.issue,
        'rft.spage' => self.start_page,
        'rft.date' => self.publication_date_year,
        'rft.issn' => (self.publication.authority.issn_isbn rescue nil),
        'rft.aulast' => self.name_strings.first.last_name
    )
  end

end
