require File.dirname(__FILE__) + '/../spec_helper'

describe Work do

  it {should belong_to(:publication)}
  it {should belong_to(:publisher)}
  it {should have_many(:name_strings).through(:work_name_strings)}
  it {should have_many(:work_name_strings).dependent(:destroy)}
  it {should have_many(:people).through(:contributorships)}
  it {should have_many(:contributorships).dependent(:destroy)}
  it {should have_many(:keywords).through(:keywordings)}
  it {should have_many(:keywordings).dependent(:destroy)}
  it {should have_many(:taggings).dependent(:destroy)}
  it {should have_many(:tags).through(:taggings)}
  it {should have_many(:users).through(:taggings)}
  it {should have_many(:external_system_uris)}
  it {should have_many(:attachments)}
  it {should belong_to(:work_archive_state)}

end
