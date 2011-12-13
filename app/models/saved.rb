# Saved model captures session-based work.ids as "items", allowing users
# to create ad-hoc lists of works for export
class Saved
  attr_reader :items

  def initialize
    @items = []
  end

  def add_work(work)
    @items << work.id unless @items.member?(work.id)
  end

  def remove_work(work_id)
    @items.delete(work_id)
  end

  def all_works
    @items.collect do |id|
      Work.find_by_id(id)
    end.compact
  end

end