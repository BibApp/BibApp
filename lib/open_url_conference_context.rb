module OpenUrlConferenceContext
  def open_url_context_hash
    self.open_url_base_context_hash.merge(
        'rft_val_fmt' => 'info:ofi/fmt:kev:mtx:journal',
        'genre' => 'proceeding',
        'atitle' => self.title_primary,
        'jtitle' => (self.publication.authority.name rescue nil),
        'volume' => self.volume,
        'issue' => self.issue,
        'spage' => self.start_page,
        'date' => self.publication_date.try(:year),
        'issn' => (self.publication_authority.authority.issn_isbn rescue nil),
        'aulast' => self.name_strings.first.last_name
    )
  end
end