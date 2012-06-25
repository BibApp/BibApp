class ISBN < Identifier

  validates_presence_of :name

  def self.id_formats
    [:isbn]
  end

  # I'm not sure this is guaranteed to work (e.g. that every stem as produced will become a valid ISBN
  # by appending one of the possible check digits, but I think it's okay and it seems to work.
  def self.random
    stem = '978' + 9.times.collect { ActiveSupport::SecureRandom.random_number(10) }.join('')
    ((0..9).to_a << 'X').each do |tail|
      candidate = stem + tail.to_s
      return candidate if self.is_valid?(candidate)
    end
  end

  def self.cleanup(identifier)
    Lisbn.new(identifier).isbn
  end

  def self.is_valid?(identifier)
    Lisbn.new(identifier).valid?
  end

#  def clean_response(isbn_response)
#    # Assuming we want first result from response list
#    data = Hash.new
#    data[:isbn] = isbn_response.data["list"][0]["isbn"]
#    data[:city] = isbn_response.data["list"][0]["city"]
#    data[:title] = isbn_response.data["list"][0]["title"]
#    data[:publisher] = isbn_response.data["list"][0]["publisher"]
#    data[:language] = isbn_response.data["list"][0]["lang"]
#    data[:year] = isbn_response.data["list"][0]["year"]
#    data[:form] = isbn_response.data["list"][0]["form"]
#    data[:oclcnum] = isbn_response.data["list"][0]["oclcnum"]
#    return data
#  end
end