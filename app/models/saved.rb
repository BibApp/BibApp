# Saved model captures session-based work.ids as "items", allowing users
# to create ad-hoc lists of works for export 
class Saved < ActiveRecord::BaseWithoutTable
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