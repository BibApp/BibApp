class PeopleImporter
  
  attr_reader :alias_hash, :parser, :status
  
  def initialize(fields, parser)
    @alias_hash = fields
    @parser = parser
    @status = {:new => 0, :updated => 0, :error => '', :skipped => 0}
  end
  
  def process(row)
    record = Hash.new
    arr = row.to_a.flatten
    0.step(arr.length,2){ |pos| 
      record[@alias_hash[arr[pos]]] = arr[pos+1] unless @alias_hash[arr[pos]].nil? 
    }

    begin
      
      record.each do |k,v|
        next if v.nil? 
        if @parser.respond_to?("#{k}=")
           record[k] = @parser.send("#{k}=".to_sym, v)
        end
      end
      
      userid = record[:uid]
    
      if ensure_first_name_columnmatch(record) == false
        @status[:error] = "Column name mismatch. Please review requirements for field column names in config/batchload_authors"
        return
      end
      
      # skip empty values, ignore fields labeled as such
      # but not nil values in case this is an update
      record.delete_if {|k,v| v.nil?}
      record.delete_if {|k,v| v.strip.empty?} #unless v.nil?} 
      record.delete_if {|k,v| k == :ignore}
      
      record = @parser.send(:post_process, record) if @parser.respond_to?("post_process")

      # post_process might want to skip adding a person record based on some criteria
      unless record.empty? || record.nil?
        
        insure_machine_display_names(record)
        remove_unrecognized_keys(record)
         
        unless ( ::Person.exists?(['uid = ?', userid]) )
          db = ::Person.new(record)
          db.save!
          @status[:new] +=1
        else
          
          if @parser.respond_to?("pre_process_save")
            
            # status of an employee may have changed
            db = ::Person.find_by_uid(userid)
            
            # issues one might encounter:
            # blind updating that overwrites user entered values
            # or needless updating if nothings changed
            if @parser.send(:pre_process_save, db, record) == true
              db.update_attributes(record)
              db.save!
              @status[:updated] +=1
            end
            
          end
        end
      
      else
        # for msk this is terminated
        @status[:skipped] +=1
      end
      
    rescue Exception => e
      # backtrace written to log
      # TODO putting it in a comment on the form
      @status[:error] = "Error: uid=#{userid}: #{e.to_s}. " + "BACKTRACE" + e.backtrace.to_s
    end
      
  end
  
  # setting both machine and display names
  # requires first and last name at minimum
  # client doesn't need to set these
  def insure_machine_display_names(record)
    fn = record[:first_name].strip
    mn = record.has_key?(:middle_name) ? record[:middle_name].strip : ''
    ln = record[:last_name].strip
    
    # middle name needs to be empty string not nil otherwise gsub nil error on pen_names in person model 
    record[:middle_name] = mn
    record.delete(:display_name) if record[:display_name] && record[:display_name].strip.empty?
    record.delete(:machine_name) if record[:machine_name] && record[:machine_name].strip.empty?
    
    unless record.has_key?(:display_name)
      record[:display_name] = mn.empty? ? "#{fn} #{ln}" : "#{fn} #{mn} #{ln}"
    end
    if record.has_key?(:machine_name) 
      record[:machine_name] = record[:machine_name].downcase 
    else
      record[:machine_name] = record[:display_name].downcase 
    end
  end
  
  # a client can easily mislabel a field in the config hash file
  # this insures the record is saved, 
  # better than generating an error 
  def remove_unrecognized_keys(record)
    person_db_schema = ::Person.column_names - ["id", "created_at", "updated_at", "scoring_hash"]
    record.delete_if { |k,v| person_db_schema.include?(k.to_s) == false }
  end
  
  # idiot check for the most obvious incompatability
  def ensure_first_name_columnmatch(record)
    return record.has_key?(:first_name)
  end
  
  def status
    @status
  end
  
  
end
