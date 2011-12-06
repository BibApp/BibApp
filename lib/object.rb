class Object
  #return the value if the receive is blank and the default if not
  def if_blank(value, default = nil)
    self.blank? ? value : default
  end

  #return self if not blank, default otherwise
  def self_or_blank_default(default)
    self.if_blank(default, self)
  end
end