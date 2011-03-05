class AddAuthorityKeysToWorks < ActiveRecord::Migration
  def self.up

    # 1) Add authority fields to Works
    # 2) Find all Works
    # 3) Set publication authority, publisher authority, batch_index
    # 4) Save without callbacks
    # 5) Index.batch_index
     
     add_column :works, :authority_publication_id, :integer
     add_column  :works, :authority_publisher_id, :integer
     
     works = Work.find(:all)
     works.each do |work|

       if !work.publication.nil?
         work.authority_publication_id  = work.publication.authority.id
         work.authority_publisher_id    = work.publication.authority.publisher.id
         work.set_for_index_and_save
       end
     end
     
     Index.batch_index
  end

  def self.down
    remove_column :works, :authority_publication_id
    remove_column :works, :authority_publisher_id
  end
end
