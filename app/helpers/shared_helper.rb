#this helper is for views in the shared folder
#since we don't know from whence they are called this is included into all views by ApplicationController -
#nevertheless, I want the separation from the methods in ApplicationHelper - these are really specific to
#the shared views, not all views
module SharedHelper

  def letter_link_for(letters, letter, current, path)
    li_opts = (current == true) ? {:class => "current"} : {}
    link = path ? "#{path[:path]}?page=#{letter}" : {:page=> letter}
    content_tag(:li, (letters.index(letter) ? link_to(letter, link, :class => "some") : content_tag(:a, letter, :class => 'none')), li_opts)
  end

  def link_to_authors(work)
    links = Array.new

    if work['authors_data'] != nil
      work['authors_data'].first(5).each do |au|
        name, id = NameString.parse_solr_data(au)
        links << link_to(h("#{name.gsub(",", ", ")}"), name_string_path(id), {:class => "name_string"})
      end

      if work['authors_data'].size > 5
        links << link_to("more...", work_path(work['pk_i']))
      end
    end

    links.join(", ").html_safe
  end

  def link_to_editors(work)
    if work['editors_data'] != nil
      # If no authors, editors go first
      str = work['authors_data'] ? "In " : ''
      links = Array.new

      work['editors_data'].first(5).each do |ed|
        name, id = NameString.parse_solr_data(ed)
        links << link_to(h("#{name.gsub(",", ", ")}"), name_string_path(id), {:class => "name_string"})
      end

      if work['editors_data'].size > 5
        links << link_to("more...", work_path(work['pk_i']))
      end

      str += links.join(", ")
      str += " (Eds.), "
      str
    end
  end

  def link_to_work_publication(work)
    if work['publication_data'].blank?
      "Unknown"
    else
      pub_name, pub_id = Publication.parse_solr_data(work['publication_data'])
      link_to("#{pub_name}", publication_path(pub_id), {:class => "source"})
    end
  end

  def link_to_work_publisher(work)
    if work['publisher_data'].blank?
      "Unknown"
    else
      pub_name, pub_id = Publisher.parse_solr_data(work['publisher_data'])
      link_to("#{pub_name}", publisher_path(pub_id), {:class => "source"})
    end
  end

  def add_filter(params, facet, value, count)
    filter = Hash.new
    if params[:fq]
      filter[:fq] = params[:fq].collect
    else
      filter[:fq] = []
    end

    filter[:fq] << "#{facet}:\"#{value}\""
    filter[:fq].uniq!

    link_to "#{value} (#{count})", params.merge(filter)
  end

  def remove_filter(params, facet)
    filter = Hash.new
    if params[:fq]
      filter[:fq] = params[:fq].collect
      filter[:fq].delete(facet)
      filter[:fq].uniq!

      #Split filter into field name and display value (they are separated by a colon)
      field_name, display_value = facet.split(':')
      link_to "#{display_value}", params.merge(filter)
    end
  end

  #Determines the pretty name of a particular Work Status
  def work_state_name(work_state_id)
    #Load Work States hash from personalize.rb
    $WORK_STATUS[work_state_id]
  end

end