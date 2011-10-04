module SearchHelper
  def search_example(key)
    $SEARCH_EXAMPLES ||= Hash.new
    $SEARCH_EXAMPLES[key]
  end
end
