require 'lib/open_url_conference_context'
class ConferencePoster < Work
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
    "http ://purl.org/eprint/type/ConferencePoster"
  end

end