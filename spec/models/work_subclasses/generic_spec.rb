require File.join(Rails.root, 'spec', 'spec_helper')

describe Generic do

  it_should_behave_like "a title_primary validating work subclass", Generic,
                        ['Creator', 'Contributor'], 'Creator',
                        'Contributor', "http://purl.org/eprint/type/ScholarlyText"
end
