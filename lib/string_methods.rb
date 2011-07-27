require 'cmess/guess_encoding'

class EncodingException < Exception;
end

module StringMethods
  module_function

  #return a UTF8 version of the string, throwing an EncodingException if there
  #is a problem
  def ensure_utf8(str)
    return str if str.is_utf8?
    encoding = CMess::GuessEncoding::Automatic.guess(str)
    # As long as encoding could be guessed, try to convert to UTF-8
    unless encoding.blank? or (encoding == CMess::GuessEncoding::Encoding::UNKNOWN)
      return Iconv.iconv('UTF-8', encoding, str).to_s
    else
      raise EncodingException
    end

  end

end