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
      return Iconv.iconv('UTF-8', encoding, str).join
    else
      Rails.logger.error "Unable to convert string encoding with #{encoding} guess by CMess - trying brute force"
      return convert_string(str)
    end
  end

  #This is an example of another way we might approach this.
  def convert_string(str)
    #TODO might want to use a cut-down or reordered list here
    Encoding.list.each do |encoding|
      begin
        s = str.clone
        s.force_encoding(encoding)
        if s.valid_encoding?
          return s.encode('UTF-8', encoding)
        end
      rescue
        #do nothing - let it go to next candidate
      end
    end
    raise EncodingException, "Could not convert to any encoding: #{str}"
  end

end