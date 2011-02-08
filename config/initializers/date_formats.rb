# Define custom Date/Time formats for BibApp
# These can be used similar to as follows:
#   @work.created_at.to_s(:xsd) -> Calls ':xsd' format
#
bibapp_date_formats = {
  #xsd:datetime Format - e.g. "2007-09-29T00:00:00"
  :xsd => "%Y-%m-%dT%H:%M:%S"
}

#Load custom formats for Date / DateTime / Time classes
Time::DATE_FORMATS.merge!(bibapp_date_formats)
Date::DATE_FORMATS.merge!(bibapp_date_formats)
