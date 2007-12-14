module SearchHelper
  def add_filter(filters, field, value)
    link = Array.new
    link << filters
    link << "#{field.singularize}:#{value}"
    link.flatten!
    link.each{|l| l.strip!}
    return link.join(", ")
  end
  
  def remove_filter(filters, filter)
    link = Array.new
    link << filters
    link.flatten!
    link.each{|l| l.strip!}
    link.delete(filter)
    return link.join(", ")
  end
end
