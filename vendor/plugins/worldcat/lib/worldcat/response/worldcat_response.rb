class WorldCatResponse < WorldCat
  
  attr_accessor :data, :format, :method, :evaluated
  
  def initialize(data, format, method)
    @format = format
    @method = method
    
    if @format == 'ruby'
      @data = eval(data)
      @evaluated = true
    else
      # Deal with eval on your own...
      @data = data
      @evaluated = false
    end
  end
  
  def evaluated?
    @evaluated
  end
end