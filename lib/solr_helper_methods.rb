module SolrHelperMethods
  #by default apply simple_to_param to receiver's name
  #override if necessary
  def to_param
    simple_to_param(self.name)
  end

  protected

  def simple_to_param(name)
    param_name = name.gsub(" ", "_")
    param_name = param_name.gsub(/[^A-Za-z0-9_]/, "")
    "#{id}-#{param_name}"
  end


end