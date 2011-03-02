require File.join(Rails.root, 'spec', 'spec_helper')

describe JournalWhole do

  it_should_behave_like "a title_primary validating work subclass", JournalWhole,
                        ['Editor', 'Managing Editor', 'Editorial Board Member'],
                        'Editor', 'Editorial Board Member', nil

end
