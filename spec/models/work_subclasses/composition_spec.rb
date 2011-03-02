require File.join(Rails.root, 'spec', 'spec_helper')

describe Composition do

 it_should_behave_like "a title_primary validating work subclass", Composition, ['Composer'], 'Composer',
                        'Composer', nil
  
end
