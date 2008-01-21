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
    end
    
    before :new do
      if params[:q]
        @ldap_results = ldap_search(params[:q])
      end
    end
    
    before :show do
      @person = Person.find(params[:id])
      @citations = Citation.paginate(
        :all,
        :joins =>
          "join authorships on citations.id = authorships.citation_id
          join authors on authorships.author_id = authors.id
          join pen_names on authors.id = pen_names.author_id
          join people on pen_names.person_id = people.id",
        :conditions => ["people.id = ? and citations.citation_state_id = ?", params[:id], 3],
        :order => "citations.year DESC, citations.title_primary",
        :page => params[:page] || 1,
        :per_page => 10
      )
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