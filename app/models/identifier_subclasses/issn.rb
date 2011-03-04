class ISSN < Identifier
  validates_presence_of :name

  def self.id_formats
    [:issn]
  end

  def self.random
    stem = 7.times.collect {ActiveSupport::SecureRandom.random_number(10)}.join('')
    ((0..9).to_a << 'X').each do |tail|
      candidate = stem + tail.to_s
      return candidate if self.is_valid?(candidate)
    end
  end

  def self.cleanup(identifier)
    identifier.gsub(/[^\dX]/i, '')
  end

  def self.is_valid?(identifier)
    issn = self.cleanup(identifier)

    if issn.length != 8
      return false
    end

    chars = issn.split('')
    if chars[7].upcase == 'X'
      chars[7] = 10
    end

    sum = 0

    0.upto(chars.size) do |i|
      sum += ((8-i) * chars[i].to_i)
    end

    return ((sum % 11) == 0)
  end

#  def clean_response(issn_response)
#    # Assuming we want first result from response list
#    data = Hash.new
#    data[:issn] = issn_response.data["group"][0]["list"][0]["issn"]
#    data[:issnl] = issn_response.data["group"][0]["list"][0]["issnl"]
#    data[:rssurl] = issn_response.data["group"][0]["list"][0]["rssurl"]
#    data[:title] = issn_response.data["group"][0]["list"][0]["title"]
#    data[:publisher] = issn_response.data["group"][0]["list"][0]["publisher"]
#    data[:peerreview] = issn_response.data["group"][0]["list"][0]["peerreview"]
#    data[:form] = issn_response.data["group"][0]["list"][0]["form"]
#    data[:rawcoverage] = issn_response.data["group"][0]["list"][0]["rawcoverage"]
#    data[:oclcnum] = issn_response.data["group"][0]["list"][0]["oclcnum"]
#    return data
#  end
end