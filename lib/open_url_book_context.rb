module OpenUrlBookContext
  def open_url_context_hash
    self.open_url_base_context_hash.merge(
      'rft_val_fmt' => 'info:ofi/fmt:kev:mtx:book',
      'genre' => 'book',
      'btitle' => self.title_primary,
      'date' => self.publication_date_year,
      'isbn' => (self.publication.authority.issn_isbn rescue nil),
      'aulast' => self.name_strings.first.last_name
    )
  end
end