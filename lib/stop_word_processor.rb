#remove stopwords from a string or array or strings.
#We assume that the string has already been processed to remove punctuation and to compress spaces (e.g. by
#creating a machine name) as this is our real use case at this point.
#We are not permitted to trim the last word so that cases like 'A The' won't fail outright - however clearly they needn't
#behave sensibly.
require 'singleton'
require 'set'

class StopWordProcessor
  include Singleton

  attr_accessor :stopword_set

  def initialize
    self.stopword_set = YAML.load_file(File.join(Rails.root, 'config', 'stopwords.yml')).collect { |word| word.downcase }.to_set
  rescue
    self.stopword_set = Set.new
  end

  def trim_string_left(string)
    string.blank? ? '' : trim_array_left(string.split(" ")).join(" ")
  end

  def trim_array_left(array)
    if array.length == 1 or not is_stopword?(array.first)
      array
    else
      trim_array_left(array.drop(1))
    end
  end

  def is_stopword?(word)
    self.stopword_set.member?(word.downcase)
  end

end