### uses fastercsv
###  see config/batchload_authors for uploads requiring customization 


require "#{File.expand_path(File.dirname(__FILE__))}/../app/models/person"
require "#{File.expand_path(File.dirname(__FILE__))}/../config/batchload_authors"
require 'batchload/people_importer'
Dir["#{File.expand_path(File.dirname(__FILE__))}/batchload/*_person.rb"].each { |p| require p }


class CsvPeopleUpload < Struct.new(:csv_text, :user_id, :filename)
 
  # required for DelayedJob
  def perform
    batch_persons_csv(csv_text, user_id, filename)
  end    

  def batch_persons_csv(str, user_id, filename)
    begin
      
      results = batch_process(str) 
      if results[:error].empty?
        results = "Total processed: #{results[:total]}: (#{results[:new]} new, #{results[:updated]} updated)"
      else
        msg, backtrace = results[:error].split('BACKTRACE')
        msg += ". Error in the import file at line #{results[:total]}" if results[:total]
        msg += ":: #{backtrace.gsub(/:in\s/, "\n")}" unless backtrace.nil?
        results = msg
      end
      
    rescue Exception => e
      results = "An error was generated processing your request. #{e.to_s}"
    
    end
    
    Notifier.deliver_batch_import_persons_notification(user_id, results, filename)
    
  end
  

  def batch_process(data)
    dbfields_alias = Hash.new

    if not defined?($ALIAS_MATCH_PERSON) || (defined?($ALIAS_MATCH_PERSON) && $ALIAS_MATCH_PERSON.empty?)
      people_columns = ::Person.column_names
      fields_for_update = people_columns - ["id", "created_at", "updated_at", "scoring_hash"]
      
      fields_for_update.collect{|x| dbfields_alias[x.to_s] = x.to_sym }
    else
      dbfields_alias = $ALIAS_MATCH_PERSON
    end

    $PERSON_COLUMN_DELIMITER = ',' unless defined?($PERSON_COLUMN_DELIMITER)
    $EMPLOYEE_IMPORTER = 'DefaultPerson' unless defined?($EMPLOYEE_IMPORTER)
    parser = Object.const_get($EMPLOYEE_IMPORTER).new(dbfields_alias)
    
    cnt = 2
    FasterCSV.parse(data, {:headers=>true, :col_sep=>$PERSON_COLUMN_DELIMITER}) do |row|
      parser.process(row)
      break unless parser.status[:error].empty?
      cnt +=1
    end
    
    parser.status[:total] = cnt-2
    return parser.status
  end

end
