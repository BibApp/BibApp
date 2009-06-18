class XIDRequest < WorldCatRequest
  
  attr_accessor :validators
  
  def initialize(rec_num, args={})
    @rec_num = rec_num
    @args = {}
    @args.merge!(args)
    
    if !@args.include?(:method)
      @args[:method] = 'getEditions'
    end
    
    if !@args.include?(:format)
      @args[:format] = 'ruby'
    end
    
    if !@args.include?(:fl)
      @args[:fl] = '*'
    end
  end
  
  def get_response
    data = self.http_get()
    format = @args[:format]
    method = @args[:method]
    return XIDResponse.new(data, format, method)
  end
  
  def valid?
    if self.validators[:method].include?(@args[:method]) && self.validators[:format].include?(@args[:format])
      return true
    else
      return false
    end
  end
  
end

class XISSNRequest < XIDRequest
  
  # xISSN requests
  def initialize(rec_num, args={})
    super(rec_num, args)
    @validators = {
      :method => ['getForms', 'getHistory', 'fixChecksum', 'getMetadata', 'getEditions', 'hyphen'],
      :format => ['xml', 'html', 'json', 'python', 'ruby', 'text', 'csv', 'php']
    }
    
  end
  
  def api_url
    "http://xissn.worldcat.org/webservices/xid/issn/#{@rec_num}"
  end
end

class XISBNRequest < XIDRequest
  
  # xISBN requests
  def initialize(rec_num, args={})
    super(rec_num, args)
    @validators = {
      :method => ['to10', 'to13', 'fixChecksum', 'getMetadata', 'getEditions'],
      :format => ['xml', 'html', 'json', 'python', 'ruby', 'text', 'csv', 'php']
    }
  end
  
  def api_url
    "http://xisbn.worldcat.org/webservices/xid/isbn/#{@rec_num}"
  end
end

class XOCLCNUMRequest < XIDRequest
  
  # xOCLCNUM requests
  def initialize(rec_num, args={})
    super(rec_num, args)
    @numtype = "oclcnum"
    @validators = {
      :method => ['getVariants', 'getMetadata', 'getEditions'],
      :format => ['xml', 'html', 'json', 'python', 'ruby', 'text', 'csv', 'php']
    }
  end
  
  def api_url
    "http://xisbn.worldcat.org/webservices/xid/#{@numtype}/#{@rec_num}"
  end
end