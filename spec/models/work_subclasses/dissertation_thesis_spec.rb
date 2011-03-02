require File.join(Rails.root, 'spec', 'spec_helper')

describe DissertationThesis do

  it_should_behave_like "a title_primary validating work subclass", DissertationThesis,
                        ['Author', 'Advisor', 'Committee Chair', 'Committee Member', 'Director of Research'],
                        'Author', 'Committee Member',  "http://purl.org/eprint/type/Thesis"
end
