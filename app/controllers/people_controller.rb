class PeopleController < ApplicationController
  require 'redcloth'
  
  make_resourceful do 
    build :index, :new, :create, :show, :edit, :update, :destroy

    publish :xml, :json, :yaml, :attributes => [
      :id, :name, :first_name, :middle_name, :last_name, :prefix, :suffix, :phone, :email, :im, :office_address_line_one, :office_address_line_two, :office_city, :office_state, :office_zip, :research_focus,
       {:name_strings => [:id, :name]},
       {:groups => [:id, :name]},
       {:contributorships => [:citation_id]}
    ]
      
    before :index do
      @a_to_z = Person.letters.collect { |d| d.letter }
      
      if params[:q]
        query = params[:q]
        @current_objects = current_objects
      else
        @page = params[:page] || @a_to_z[0]
        @current_objects = Person.find(
          :all, 
          :conditions => ["last_name like ?", "#{@page}%"], 
          :order => "last_name, first_name"
        )
      end
      
      @title = "People"
    end
    
    before :new do
      if params[:q]
        @ldap_results = ldap_search(params[:q])
      end
      @title = "Add a Person"
    end
    
    before :show do
      @query = @current_object.solr_id
      @filter = params[:fq] || ""
      @filter = @filter.split("+>+").each{|f| f.strip!}
      @sort = params[:sort] || "year"
      @page = params[:page] || 0
      @count = params[:count] || 50
      
      @q,@docs,@facets = Index.fetch(@query, @filter, @sort, @page, @count)

      @title = @current_object.name
      @research_focus = RedCloth.new(@current_object.research_focus).to_html
    end
  end

  private
  def ldap_search(query)
    begin
      require 'rubygems'
      require 'net/ldap'
      config = YAML::load(File.read("#{RAILS_ROOT}/config/ldap.yml"))[RAILS_ENV]
      logger.info "Read LDAP config:"
      config.each do |key, val|
        logger.info "#{key}: #{val}"
      end
    
      query
      if query and !query.empty?
        logger.info "Connecting to #{config['host']}:#{config['port']}"
        logger.info "Base DN: #{config['base']}"
        logger.info "Search query: #{query}"
        
        ldap = Net::LDAP.new(
          :host => config['host'], 
          :port => config['port'].to_i, 
          :base => config['base']
        )
        
        filt = Net::LDAP::Filter.eq("cn", "*#{query}*")
        res = Array.new
        return ldap.search( :filter => filt ).map{|entry| clean_ldap(entry)}
      end
    rescue Exception => e
      logger.debug("LDAP exception: #{e.message}")
      logger.debug(e.backtrace.join("\n"))
    end
    Array.new
  end
  
  def clean_ldap(entry)
    res = Hash.new("")
    entry.each do |key, val|
      res[key] = val[0]
      if [:sn, :givenname].include?(key)
        res[key] = NameCase.new(val[0]).nc!
      end
      if [:title, :o, :postaladdress, :l].include?(key)
        res[key] = res[key].titleize
      end
    end
    return res
  end
end