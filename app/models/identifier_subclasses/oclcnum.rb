=begin
class OCLCNUM < Identifier
  validates_presence_of :name

  class << self
    def id_formats
      [:oclcnum]
    end
  end

  def parse_identifier(identifier)
    oclcnum_request = XOCLCNUMRequest.new(identifier, {:method => "getMetadata"})

    if oclcnum_request.valid?
      oclcnum_response = oclcnum_request.get_response
      if oclcnum_response.data['stat'] == "ok"
        format = "OCLCNUM"
        return format, identifier, oclcnum_response
      else
        return nil
      end
    else
      return nil
    end
  end
end
=end