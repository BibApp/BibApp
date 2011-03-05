class AddInitialPubKeys < ActiveRecord::Migration

  def self.up
    
    ### Authorities done right.
    # * Work authority publication and publisher have lost their pretty syntax
    # * Let's keep inital pub values, and set authority data through Rails' expected association foreign keys
    # * This is gonna make work.publication.name work again, displaying "authority" data.
    
    # 1) Add new initial pub_keys
    # 2) Find all works
    # 3) Ensure authority_publication_id and authority_publisher_id fields are not empty
    # 4) Set initial_publication_id to publication_id, initial_publisher_id to publisher_id
    # 5) Set publication_id = authority_publication_id, publisher_id = authority_publisher_id
    # 6) Save and set for index without callbacks
    # 7) Index.batch_index

    say_with_time "Adding work inital pub keys..." do
      add_column :works, :initial_publication_id, :integer
      add_column :works, :initial_publisher_id, :integer
      add_column :publications, :initial_publisher_id, :integer

    
      Publication.all.each do |publication|
        say " = Publication #{publication.id}", true
  
        ### Populate the new intial pub_keys
        say " - populating intial pub keys", true
        publication.initial_publisher_id = publication.publisher_id
  
        ### Set the pub_keys to their authority mappings
        say " - remapping pub keys", true
        # Set publication_id
        publication.publisher_id = publication.authority.publisher.id
        publication.save
        say "\n", true
      end

      Work.all.each do |work|
      
        say " = Work #{work.id}", true
        
        ### Make sure authority is captured
        say " - setting authority", true
        # Set authority_publication_id
        if work.authority_publication_id.nil?
          work.authority_publication_id  = work.publication_id
        end

        # Set authority_publisher_id
        if work.authority_publisher_id.nil?
          work.authority_publisher_id = work.publisher_id
        end
      
        ### Populate the new intial pub_keys
        say " - populating intial pub keys", true
        # Set initial_publication_id
        work.initial_publication_id = work.publication_id
      
        # Set initial_publisher_id
        work.initial_publisher_id = work.publisher_id
      
        ### Set the pub_keys to their authority mappings
        say " - remapping pub keys", true
        # Set publication_id
        work.publication_id = work.authority_publication_id
      
        # Set publisher_id
        work.publisher_id = work.authority_publisher_id
      
        ### Save everything.
        # Save work and mark for batch indexing
        work.set_for_index_and_save
        say "\n", true
      end
    end
    
    # Index everything
    Index.batch_index
  end

  def self.down
    # No turning back.
    raise ActiveRecord::IrreversibleMigration, "Sorry, critical API migration -- you can't migrate down."
  end
end