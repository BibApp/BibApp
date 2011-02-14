## for any customization don't modify this file, rather create a new subclass of PeopleImporter
## see mskcc_person as an example

class DefaultPerson < PeopleImporter
  def initialize(fields)
    super(fields, self)
  end

  def process(row)
    super(row)
  end
  
end
