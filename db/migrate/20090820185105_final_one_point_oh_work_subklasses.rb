class ConferenceProceeding < Work
  validates_presence_of :title_primary
end

class FinalOnePointOhWorkSubklasses < ActiveRecord::Migration
  
  def self.up
    
    say_with_time "Updating work subtypes..." do
      works = Work.where(:type => 'ConferenceProceeding').all
      ri_a = Array.new
      works.each do |w|
        if w.type.to_s == "ConferenceProceeding"
          w.update_type_and_save('ConferencePaper')
          say "Work #{w.id} changed from ConferenceProceeding to ConferencePaper!", true
        end
        ri_a << w
      end
      Index.batch_update_solr(ri_a)
    end
  end

  def self.down
    # No turning back.
    raise ActiveRecord::IrreversibleMigration, "Sorry, you can't migrate down."
  end
end
