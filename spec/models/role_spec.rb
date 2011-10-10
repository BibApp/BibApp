require File.dirname(__FILE__) + '/../spec_helper'

describe Role do

  it { should have_and_belong_to_many(:users) }
  it { should belong_to(:authorizable) }

  context 'describing itself' do

    it 'for object' do
      work = Factory.create(:book_whole)
      role = Role.new(:name => 'editor', :authorizable_type => 'Work', :authorizable_id => work.id)
      role.description.should == "editor of Book Whole '#{work.name}'"
    end

    it 'for class' do
      role = Role.new(:name => 'editor', :authorizable_type => 'Work')
      role.description.should == 'editor of Work'
    end

    it 'for System' do
      role = Role.new(:name => 'editor')
      role.description.should == 'editor (generic role)'
    end

  end
end


