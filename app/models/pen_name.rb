# PenNames provide the logic for creating and destroying Contributorships
#   see the PenNameObserver for how these Contributorships are created/destroyed
class PenName < ActiveRecord::Base
  belongs_to :name_string
  belongs_to :person
  has_many :contributorships, :dependent => :destroy
  has_many :works, :through => :contributorships

  validates_presence_of :name_string_id, :person_id

  after_save :after_save_actions
  before_destroy :before_destroy_actions

  scope :for_name_string, lambda {|name_string_id| where(:name_string_id => name_string_id)}

  def after_save_actions
    self.set_contributorships
    self.works.each { |work| work.save_and_set_for_index }
    Index.batch_index
  end

  def before_destroy_actions
    self.works.each { |w| w.save_and_set_for_index }
    Index.batch_index
  end

  def set_contributorships
    self.name_string.work_name_strings.each do |cns|
      #only create Contributorship for "accepted" works
      if cns.work.accepted?
        self.contributorships.find_or_create_by_work_id_and_person_id_and_role(cns.work.id, self.person_id, cns.role)
      end
    end
  end

end
