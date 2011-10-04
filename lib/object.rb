class Object
  def if_blank(value, default = nil)
    self.blank? ? value : default
  end
end