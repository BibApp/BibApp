class WorkNameString < ActiveRecord::Base
  belongs_to :name_string
  belongs_to :work
  acts_as_list :scope => :work_id

  validates_presence_of :name_string_id, :work_id
  validates_uniqueness_of :name_string_id, :scope => [:work_id, :role], :case_sensitive => true

  scope :with_role, lambda { |role| where(:role => role) }

  # Convert object into semi-structured data to be stored in Solr
  def to_solr_data
    "#{self.name_string.name}||#{self.name_string.id}||#{position}||#{role}"
  end


  def self.create_batch!(name_string_id, work_data)
    cites = Work.import_batch!(work_data)
    create_batch_from_works!(name_string_id, cites)
    return cites
  end

  def self.create_batch_from_works!(name_string, works)
    return unless works.respond_to?(:each)
    works.each do |c|
      WorkNameString.create(:name_string_id => name_string.id, :work_id => c.id)
    end
  end

end
