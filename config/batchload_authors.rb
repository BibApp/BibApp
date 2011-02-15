
### Person / Author batchload using CSV delimited files
### access via admin login people
### 

$PERSON_COLUMN_DELIMITER = ','

#
# see lib/author_batch_load
# two constants need to be defined if any customization is required
# $EMPLOYEE_IMPORTER and $ALIAS_MATCH_PERSON

# any customization requires a class modeled after lib/batchload/example_person.rb
# uncomment the following to reference the class controlling custom processing
# $EMPLOYEE_IMPORTER = 'ExamplePerson'

## a csv file with these columns are the defaults
## using these as the first row of the csv require no further customization
## only 3 fields are required in BibApp I believe, so that's the case here
## what I believe are the default fields in BibApp

#  external_id, 
#  first_name,  -- required
#  middle_name, 
#  last_name,   -- required
#  uid,         -- required
#  prefix, 
#  suffix, 
#  image_url, 
#  phone, 
#  email, 
#  im, 
#  office_address_line_one, 
#  office_address_line_two, 
#  office_city, 
#  office_state, 
#  office_zip, 
#  research_focus, 
#  active,      -- currently not being used by BibApp 
#  machine_name, 
#  display_name, 
#  postal_address, 


# 
# mapping of CSV file to Person database schema
# not necessary if the CSV fields match the field names in the person database
#
# Use In the form of a hash, with the key being the CSV column as a string
# and the hash value as a symbol (mostly for readability) that names the person model field names
# $ALIAS_MATCH_PERSON = {'id' => :uid, 
#                       'first' => :first_name, 
#                       'last' => :last_name, 
#                       'full' => :display_name, 
#                       'org' => :organization, 
#                       'start date' => :start_date
#                       }

# following are fields in sample csv file 
# these are all csv columns, for not used can set the hash value :ignore
# alternatively, comment out fields not wanted or exclude in the hash
# the key names are our from the sample csv columns
# $ALIAS_MATCH_PERSON = {'EMPLOYEE_ID' => :uid,
#                       'NAME' => :ignore, # in last, first format
#                       'FIRST_NAME' => :first_name,
#                       'MIDDLE_NAME' => :middle_name,
#                       'LAST_NAME' => :last_name,
#                       'ORGANIZA_CODE' => :organization,
#                       'BUSINESS_UNIT' => :ignore, # not useful
#                       'BUSINESSNAME' => :buname,
#                       'DEPTID' => :ignore, # not useful
#                       'DEPTNAME' => :dept_name,
#                       'JOBTITLE' => :job_title,
#                       'PERSON_ORG' => :ignore, # not used
#                       'EMPLOYEE_STATUS' => :emp_status, 
#                       'HIRE_DT' => :start_date,
#                       'TERM_DT' => :end_date
#                      }

