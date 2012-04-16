module MachineName
  module_function
  #Machine name is a string with:
  #  1. all punctuation/spaces converted to single space
  #  2. stripped of leading/trailing spaces and downcased
  # Note we do this in a way that avoids modifying the original string or its mb_chars!
  def make_machine_name(string)
    normalized_string = string.mb_chars.gsub(/[\W]+/, " ")
    normalized_string.strip.downcase.to_s
  end

  def make_machine_name_from_array(array_of_strings)
    make_machine_name(array_of_strings.join(" "))
  end

end

module MachineNameUpdater
  include MachineName
  def update_machine_name(force = false)
    if self.name_changed? or force
      self.machine_name = make_machine_name(self.name)
    end
  end
end