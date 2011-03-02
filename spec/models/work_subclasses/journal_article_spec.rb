require File.join(Rails.root, 'spec', 'spec_helper')

describe JournalArticle do

  it_should_behave_like "a title_primary validating work subclass", JournalArticle, ['Author'], 'Author',
                          'Author', "http://purl.org/eprint/type/JournalArticle"

end
