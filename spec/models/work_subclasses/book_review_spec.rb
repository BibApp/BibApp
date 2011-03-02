require File.join(Rails.root, 'spec', 'spec_helper')

describe BookReview do

  it_should_behave_like "a title_primary validating work subclass", BookReview, ['Author'], 'Author',
                        'Author', "http://purl.org/eprint/type/BookReview"
end
