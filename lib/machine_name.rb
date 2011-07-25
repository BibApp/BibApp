module MachineName

  #Machine name is a string with:
  #  1. all punctuation/spaces converted to single space
  #  2. stripped of leading/trailing spaces and downcased
  def make_machine_name(string)
    string.clone.mb_chars.gsub!(/[\W]+/, " ").strip.downcase
  end

  def make_machine_name_from_array(array_of_strings)
    make_machine_name(array_of_strings.join(" "))
  end

end

module MachineNameUpdater
  include MachineName
  def update_machine_name
    if self.name_changed?
      self.machine_name = self.make_machine_name(self.name)
    end
  end
end