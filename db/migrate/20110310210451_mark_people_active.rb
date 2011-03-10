#Because of some changes the active attribute of Person is now being used. However, it is likely
#nil for all records. If this is the case, then assume that this is by default rather than because
#all records have intentionally been made not active and hence mark everyone in the system as active.
class MarkPeopleActive < ActiveRecord::Migration
  def self.up
    unless Person.where(:active => true).count > 0
      Person.update_all(:active => true)
    end
  end

  def self.down
    #No way to undo this
  end
end
