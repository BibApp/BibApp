require File.join(Rails.root, 'spec', 'spec_helper')

describe PresentationLecture do

  it_should_behave_like "a title_primary validating work subclass", PresentationLecture,
                        ['Presenter'], 'Presenter', 'Presenter', nil

end
