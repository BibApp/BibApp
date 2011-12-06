module SearchHelper
  def search_example(key)
    t("personalize.search_examples.#{key.to_s.downcase}")
  end
end
