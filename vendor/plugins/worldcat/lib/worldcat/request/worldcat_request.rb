require 'net/http'

class WorldCatRequest < WorldCat
  def initialize(*args)
    @args = *args
    @validators = {}
  end
  
  def get_response
    data = self.http_get()
    format = @args['format']
    method = @args['method']
    return WorldCatResponse.new(data, format, method)
  end
  
  def http_get
    base_url = self.api_url
    args = @args.collect{|k,v| "#{k}=#{v}"}.join("&")
    url = "#{base_url}?#{args}"
    resp = Net::HTTP.get_response(URI.parse(url))
    data = resp.body
    return data
  end
  
  def subclass_validator
    # @TODO
  end
  
  def validate
    # @TODO
  end
  
end