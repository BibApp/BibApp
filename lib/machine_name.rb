module MachineName

  #Machine name is a string with:
  #  1. all punctuation/spaces converted to single space
  #  2. stripped of leading/trailing spaces and downcased
  def make_machine_name(string)
    string.mb_chars.gsub!(/[\W]+/, " ").strip.downcase
  end
end