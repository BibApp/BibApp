class JournalArticle < Work
  validates_presence_of :title_primary

  class << self
    def roles
      ['Author']
    end

    def creator_role
      'Author'
    end

    def contributor_role
      'Author'
    end
  end
  
  def open_url_kevs
    open_url_kevs = Hash.new
    open_url_kevs[:format]     = "&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal"
    open_url_kevs[:genre]      = "&rft.genre=article"
    open_url_kevs[:title]      = "&rft.atitle=#{CGI.escape(self.title_primary)}"
    unless self.publication.nil?
      open_url_kevs[:source]     = "&rft.jtitle=#{CGI.escape(self.publication.authority.name)}"
      open_url_kevs[:issn]       = "&rft.issn=#{self.publication.issns.first[:name]}" if !self.publication.issns.empty?
    end
    open_url_kevs[:date]       = "&rft.date=#{self.publication_date}"
    open_url_kevs[:volume]     = "&rft.volume=#{self.volume}"
    open_url_kevs[:issue]      = "&rft.issue=#{self.issue}"
    open_url_kevs[:start_page] = "&rft.spage=#{self.start_page}"
    open_url_kevs[:end_page]   = "&rft.epage=#{self.end_page}"
    
    return open_url_kevs
  end
end
