#mixin for updating a sort_name field from a supplied name (for our use currently always a machine name)
require 'lib/stop_word_processor'
require 'lib/machine_name'

module StopWordNameSorterClassMethods
  def update_all_sort_names
    self.all.each do |instance|
      instance.update_sort_name
      instance.save if instance.changed?
    end
  end
end

module StopWordNameSorter
  #if the string hasn't already been processed into a machine_name then pass a true second argument and this
  #will be done
  def self.included(klass)
    klass.extend(StopWordNameSorterClassMethods)
  end

  def update_sort_name(name = self.machine_name, canonicalize = false)
    name = MachineName.make_machine_name(name) if canonicalize
    self.sort_name = StopWordProcessor.instance.trim_string_left(name)
  end
end
