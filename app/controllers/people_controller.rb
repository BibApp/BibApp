class PeopleController < ApplicationController
  make_resourceful do 
    build :all

    before :index do
      @people = Person.paginate(
        :all,
        :order => "last_name",
        :page => params[:page] || 1,
        :per_page => 10
      )
      @title = "People"
    end
    
    before :new do
      if params[:q]
        @ldap_results = ldap_search(params[:q])
      end
      @title = "Add a Person"
    end
    
    before :show do
      @person = Person.find(params[:id])
      @contributorships = @person.contributorships.to_show.paginate(
        :page => params[:page] || 1,
        :per_page => 10
      )
      
      @title = @person.first_last
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
        
        ldap = Net::LDAP.new(:host => config['host'], :port => config['port'].to_i, :base => config['base'])
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