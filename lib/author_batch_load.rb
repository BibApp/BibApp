###  see config/batchload_authors for uploads requiring customization

require 'csv'
require "#{File.expand_path(File.dirname(__FILE__))}/../app/models/person"
require "#{File.expand_path(File.dirname(__FILE__))}/../config/batchload_authors"
require 'batchload/people_importer'
Dir["#{File.expand_path(File.dirname(__FILE__))}/batchload/*_person.rb"].each { |p| require p }


class CsvPeopleUpload < Object

  attr_accessor(:csv_text, :user_id, :filename)

  def initialize(csv_text, user_id, filename)
    self.csv_text = csv_text
    self.user_id = user_id
    self.filename = filename
  end

  def log_action(message)
    File.open(File.join(Rails.root, 'dj.txt'), 'w+') do |f|
      f.puts "#{Time.now}: #{message}"
    end
  end

  # required for DelayedJob
  def perform
    log_action "Performing delayed job for #{filename}"
    batch_persons_csv(csv_text, user_id, filename)
  end

  def batch_persons_csv(str, user_id, filename)
    log_action "In batch persons csv"
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
      log_action "Error in batch persons csv: #{e.to_s}"
      results = "An error was generated processing your request. #{e.to_s}"

    end
    log_action "Notifying in batch_process_csv"
    Notifier.batch_import_persons_notification(user_id, results, filename).deliver
    log_action "Notified in batch_process_csv"
  end


  def batch_process(data)
    dbfields_alias = Hash.new

    if $ALIAS_MATCH_PERSON.blank?
      people_columns = ::Person.column_names
      fields_for_update = people_columns - ["id", "created_at", "updated_at", "scoring_hash"]

      fields_for_update.collect { |x| dbfields_alias[x.to_s] = x.to_sym }
    else
      dbfields_alias = $ALIAS_MATCH_PERSON
    end

    $PERSON_COLUMN_DELIMITER ||= ','
    $EMPLOYEE_IMPORTER ||= 'DefaultPerson'
    parser = Object.const_get($EMPLOYEE_IMPORTER).new(dbfields_alias)

    cnt = 2
    CSV.parse(data, {:headers => true, :col_sep => $PERSON_COLUMN_DELIMITER}) do |row|
      parser.process(row)
      break unless parser.status[:error].empty?
      cnt +=1
    end

    parser.status[:total] = cnt-2
    return parser.status
  end

end
