require File.join(Rails.root, 'spec', 'spec_helper')

shared_examples_for "a class generating sort_name" do
  before(:each) do
    @object = described_class.new
  end

  it { should respond_to(:update_sort_name) }
  it { should have_db_column(:sort_name).of_type(:string)}
  it { should be_a(StopWordNameSorter)}

end