# PenNames provide the logic for creating and destroying Contributorships
#   see the PenNameObserver for how these Contributorships are created/destroyed
class PenName < ActiveRecord::Base
  belongs_to :name_string
  belongs_to :person
  has_many :contributorships

  validates_presence_of :name_string_id, :person_id

  after_save :after_save_actions
  before_destroy :before_destroy_actions

  def after_save_actions
    # create new contributorships
    contributorships = self.set_contributorships

    works = contributorships.collect { |c| c.work }

    works.each { |work| work.save_and_set_for_index }
    Index.batch_index
  end

  def before_destroy_actions
    contributorships = self.find_contributorships

    works = contributorships.collect { |c| c.work }

    works.each { |work| work.save_and_set_for_index }
    Index.batch_index

    contributorships.each { |c| c.destroy }
  end

  def set_contributorships
    contributorships = Array.new
    self.name_string.work_name_strings.each do |cns|
      #only create Contributorship for "accepted" works
      if cns.work.accepted?
        contributorships << Contributorship.find_or_create_by_work_id_and_person_id_and_pen_name_id_and_role(
            cns.work.id,
                self.person_id,
                self.id,
                cns.role
        )
      end
    end
    return contributorships
  end

  # Find all Contributorships associated with this PenName
  def find_contributorships
    Contributorship.find(:all,
            :conditions => ["pen_name_id = ? and person_id = ?", self.id, self.person_id])
  end
end
