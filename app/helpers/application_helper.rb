# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  require 'namecase'
  require 'config/personalize.rb'
  
  def ajax_checkbox_toggle(model, person, selected)
    person = Person.find(person.id)
    if selected
      js = remote_function(
        :url => {
          :action => :destroy,
          :person_id => person.id, 
          "#{model.class.to_s.downcase}_id".to_sym => model.id},
        :method => :delete
      )
    else
      js = remote_function(
        :url => {
          :action => :create,
          :person_id => person.id, 
          "#{model.class.to_s.downcase}_id".to_sym => model.id
          },
        :method => :post
      )
    end
    check_box_tag("#{model.class.to_s.downcase}_#{model.id}_toggle", 1, selected, :onclick => js)
  end
  
  def namecase(name)
    NameCase.new(name).nc!
  end
  
  def link_to_findit(citation)
    suffix = $CITATION_SUFFIX.gsub("[title]", citation.title_primary.to_s.sub(" ", "+")).gsub("[year]", citation.year.to_s).gsub("[issue]", citation.issue.to_s).gsub("[vol]", citation.volume.to_s).gsub("[fst]", citation.start_page).gsub("[issn]", citation.publication.issn_isbn)
    link_to "Find it", "#{$CITATION_BASE_URL}?#{suffix}"
  end
  
  def archivable_count
    if Publisher.find(:all, :conditions => ["publisher_copy = '1'"]).empty?
      return @archivable_count = 0
    end
    
    archivable_publishers = Publisher.find(
      :all, 
      :select => "pub1.id, pub2.id as auth", 
      :from => "publishers pub1", 
      :joins => "join publishers pub2 on pub1.id = pub2.authority_id", 
      :conditions => "pub1.publisher_copy = 1"
    )

    pub_ids = Array.new
    archivable_publishers.each do |p|
      pub_ids << p.auth
    end

    @archivable_count = Citation.count(
      :all, 
      :conditions => ["publisher_id in (#{pub_ids.join(", ")}) and citation_state_id = 3"]
    )
    return @archivable_count
  end
  
  def add_filter(query, query_filter, facet, value, count)
    # TODO: Add Sort
    # If we have >1 filter, we need to join the facet_field:value
    if query_filter.size > 0 || !query_filter.empty?
      
      prepped_filter = Array.new
      prepped_filter << query_filter.dup
      prepped_filter << '"' + value + '"'
      prepped_filter = prepped_filter.join("+>+")

    # If we have no filters, we need to send the first
    else
      prepped_filter = '"' + value + '"'
    end
    
    link_to "#{value} (#{count})", {
      :controller => "search", 
      :action => :index, 
      :fq => prepped_filter,
      :q => query
    }
  end
  
  def remove_filter(query, query_filter, value)
    # TODO: Add Sort
    
    prepped_filter = Array.new
    prepped_filter = query_filter.dup
    prepped_filter.delete_at(prepped_filter.index(value))
    prepped_filter = prepped_filter.join("+>+")
    
    link_to "#{value}", {
      :controller => "search",
      :action => :index,
      :fq => prepped_filter,
      :q => query
    }
  end
end
