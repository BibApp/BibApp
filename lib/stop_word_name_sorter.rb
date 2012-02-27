#mixin for updating a sort_name field from a supplied name (for our use currently always a machine name)
require 'lib/stop_word_processor'
require 'lib/machine_name'

module StopWordNameSorter
  #if the string hasn't already been processed into a machine_name then pass a true second argument and this
  #will be done
  def update_sort_name(name, canonicalize = false)
    name = MachineName.make_machine_name(name) if canonicalize
    self.sort_name = StopWordProcessor.instance.trim_string_left(name)
  end
end