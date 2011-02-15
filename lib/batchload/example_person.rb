## customization used by MSKCC

class ExamplePerson < PeopleImporter
  
  def initialize(fields)
    super(fields, self)
  end

  def process(row)
    super(row)
  end
  
  #
  # CSV fields requiring special handling
  # <fieldname>=(value)
  #
  # add as needed
  #
  def start_date=(value)
    Date.parse(value, '%F').strftime('%m/%d/%Y') rescue nil
  end
  
  def end_date=(value)
    Date.parse(value, '%F').strftime('%m/%d/%Y') rescue nil
  end
  
  def last_name=(value)
    capitalize_name(value)
  end

  def first_name=(value)
    capitalize_name(value)
  end
  
  def middle_name=(value)
    capitalize_name(value)
  end
  
  #
  # post processing after record hash is created
  # don't need nil checks if base class deletes nil value hashes
  #
  def post_process(record)
    
    #
    # whatever post processing is necessary
    #
    return record
  end
  
  # return true or false
  def pre_process_save(db, record) 
    update = false
    
    #
    # whatever post processing is necessary
    #
    
    return update
  end
  
  #
  #
  private
  
  
  def capitalize_name(value)
    if value.include?(' ')
      set(value, ' ')
    elsif value.include?('-')
      set(value, '-')
    else
      value.capitalize
    end
  end
  
  def set(name, arg)
    narr = name.split(arg)
    narr.collect! {|x| x.capitalize }
    narr.join(arg)
  end
  
  
end
