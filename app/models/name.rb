class Name 
  attr_reader :last, :middle, :first 
  def initialize(last_name, first_name, middle_name) 
    @first = first_name
    @middle = middle_name
    @last = last_name
  end 
  
  def to_s 
    [ @last, @first, @middle ].compact.join(" ") 
  end 
end