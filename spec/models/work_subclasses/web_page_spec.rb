require File.join(Rails.root, 'spec', 'spec_helper')

describe WebPage do

  it_should_behave_like "a title_primary validating work subclass", WebPage, ['Author'], 'Author',
                        'Author', "http://purl.org/dc/dcmitype/InteractiveResource"


end
