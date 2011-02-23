class ISBN < Identifier
  require 'isbn/tools'
  
  validates_presence_of :name

  class << self
    def id_formats
      [:isbn]
    end
  end

  protected

  def self.cleanup(identifier)
    ISBN_Tools.cleanup(identifier)
  end

  def self.is_valid?(identifier)
    ISBN_Tools.is_valid?(identifier)
  end
  
  def clean_response(isbn_response)
    # Assuming we want first result from response list
    data = Hash.new
    data[:isbn]       = isbn_response.data["list"][0]["isbn"]
    data[:city]       = isbn_response.data["list"][0]["city"]
    data[:title]      = isbn_response.data["list"][0]["title"]
    data[:publisher]  = isbn_response.data["list"][0]["publisher"]
    data[:language]   = isbn_response.data["list"][0]["lang"]
    data[:year]       = isbn_response.data["list"][0]["year"]
    data[:form]       = isbn_response.data["list"][0]["form"]
    data[:oclcnum]    = isbn_response.data["list"][0]["oclcnum"]
    return data
  end
end