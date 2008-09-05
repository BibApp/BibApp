# Cart model captures session-based citation.ids as "items", allowing users
# to create ad-hoc lists of citations for export 
class Cart < ActiveRecord::BaseWithoutTable
  attr_reader :items
  
  def initialize
    @items = []
  end
  
  def add_work(work)
    @items << work.id
    @items.uniq!
  end
  
  def remove_work(work)
    @items.delete(work)
  end
end