require File.join(Rails.root, 'spec', 'spec_helper')

describe Grant do

  it_should_behave_like "a title_primary validating work subclass", Grant,
                        ['Principal Investigator', 'Co-Principal Investigator'],
                        'Principal Investigator', 'Co-Principal Investigator',
                        "http://purl.org/eprint/type/ScholarlyText"
end
