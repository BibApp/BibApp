class WorkNameString < ActiveRecord::Base
  belongs_to :name_string
  belongs_to :work
  acts_as_list :scope => :work_id

  validates_presence_of :name_string_id, :work_id
  validates_uniqueness_of :name_string_id, :scope => [:work_id, :role], :case_sensitive => true

  scope :with_role, lambda { |role| where(:role => role) }
  scope :author, where(:role => 'Author').order('position')
  scope :editor, where(:role => 'Editor').order('position')

  # Convert object into semi-structured data to be stored in Solr
  def to_solr_data
    "#{self.name_string.name}||#{self.name_string.id}||#{position}||#{role}"
  end

end
