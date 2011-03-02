require File.join(Rails.root, 'spec', 'spec_helper')

describe Patent do

  it_should_behave_like "a title_primary validating work subclass", Patent, ['Patent Owner'], 'Patent Owner',
                        'Patent Owner',  "http://purl.org/eprint/type/Patent"
  
end
