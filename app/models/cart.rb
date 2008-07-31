# Cart model captures session-based citation.ids as "items", allowing users
# to create ad-hoc lists of citations for export 
class Cart
  attr_reader :items
  
  def initialize
    @items = []
  end
  
  def add_citation(citation)
    @items << citation.id
    @items.uniq!
  end
  
  def remove_citation(citation)
    @items.delete(citation)
  end
end