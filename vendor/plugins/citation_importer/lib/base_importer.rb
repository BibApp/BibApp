#
# BaseImporter class
#
# All citation importers should extend this class
#
# It defines common methods for all citation importers, and performs calls
# to the @attribute_mapping and @value_translators for specific Importers.
#
class BaseImporter < CitationImporter
  #Require ParseDate for better date parsing (see parse_date method below)
  require 'parsedate'

  attr_reader :attribute_mapping, :value_translators

  def logger
    CitationImporter.logger
  end

  class << self
    #Base importer doesn't support any formats...you should
    #override this method for your importer
    def import_formats
      []
    end
  end

  ## Generate our BibApp Attribute Hash, from the given parsed citation
  def generate_attribute_hash(parsed_citation)

    logger.debug("\nGenerating attribute hash from parsed citation...\n")

    #initialize our final attribute hash
    r_hash = Hash.new

    #return immediately, if this parsed citation is not supported by importer
    if !self.class.import_formats.include?(parsed_citation.citation_type)
      logger.warning("\nThis parsed citation is not supported by importer! Skipping.\n")
      return false
    end

    #loop through parsed citation's keys & values
    parsed_citation.properties.each do |key, values|
      # Map the key (using our attribute mapping)
      r_key = self.attribute_mapping[key]

      # skip to next key if the mapping didn't work or no value translation necessary
      next if r_key.nil? or self.value_translators[r_key].nil?

      # Perform any translation of value(s) (using our value translators)
      r_val = self.value_translators[key].call(values)

      #if the value is a Hash (i.e. responds to "keys")
      if r_val.respond_to? :keys
        #Save each value separately in our final hash
        #(This covers cases where we are parsing out two or more properties
        # from a single field, e.g. parsing start & end pages out of a "pages" field)
        r_val.each do |s_key, s_val|
          r_hash[s_key] = s_val
        end
      #Else if our final hash already has this key within it
      elsif r_hash.has_key?(r_key)
        #add this value to existing key (and create an array of values)
        r_hash[r_key] = Array(r_hash[r_key]) << r_val
      else #by default, just copy our key & value to final hash
        r_hash[r_key] = r_val
      end
    end

    #if not already taken care of, copy the entire citation into :original_data
    r_hash[:original_data] = parsed_citation.properties[:original_data].to_s if r_hash[:original_data].nil?

    # TODO: this is ugly!
    # Hack for RefWorks export of Conference Proceedings:
    # RefWorks XML uses <ed> (:edition) for Conference Location
    # RefWorks RIS uses :vl
    if r_hash[:klass][0].to_s == "ConferencePaper"
      if parsed_citation.citation_type.to_s == "refworks_xml"
        r_hash[:location] = parsed_citation.properties[:edition]
        r_hash[:edition] = nil
      end
      if parsed_citation.citation_type.to_s == "ris"
        r_hash[:location] = parsed_citation.properties[:vl]
        r_hash[:volume] = nil
      end
    end


    #Note: At this point, we have a hash where some values are
    # Arrays.  However, we'll want to clean them up a bit, as we
    # may have Array values of size 1 (in which case, there's only
    # one value, and it doesn't need to be in an array)
    r_hash = cleanup_hash(r_hash)

    # Run any BaseImporter subklass callbacks
    if self.import_callbacks?
      r_hash = self.callbacks(r_hash)
    end

    #puts "Mapped Hash: #{r_hash.inspect}"
    logger.debug("\nSuccessfully generated attribute hash!\n")
    return r_hash
  end

  ## Cleanup the returned attribute hash
  def cleanup_hash(hash)
    #Final cleanup of our Hash values
    hash.each do |key, value|

      #First, flatten any arrays within arrays, etc.
      if !value.nil? and value.respond_to? :flatten
        value = value.flatten
      end

      #remove keys which have nil or empty values
      #This removes empty Arrays, Hashes and Strings
      if value.nil? or value.empty? or value[0].to_s.blank?
        hash.delete(key)
        next
      end

      #If we have an Array of Strings (or Unicode Strings) with only a single value,
      # just return the first String as the value
      if value.is_a?(Array) and value.size==1 and (value[0].is_a?(String) or value[0].is_a?(ActiveSupport::Multibyte::Chars))
        value = value[0].to_s.mb_chars.strip

        #if this is an empty string, remove it
        if value.empty?
          hash.delete(key)
          next
        end
      end

      # Finally, for Arrays/Hashes, make sure we don't have any
      # "ActiveSupport::Multibyte::Chars" as values
      # (this makes sure we are always saving strings to the database)
      if value.is_a?(Array) or value.is_a?(Hash)
        value = value.collect {|v| chars_to_string(v) }
      end


      #save cleaned value
      hash[key] = value
    end
    return hash
  end

  # Global method to parse out publication dates
  # (Can be overriden by individual importers, as necessary)
  def publication_date_parse(publication_date)
    date = Hash.new

    date[:publication_date] = parse_date(publication_date)

    return date
  end


  # Parse a date out of a string, and returns in YYYY-MM-DD format
  # (returns nil if date cannot be parsed)
  def parse_date(date_to_parse)
    date = nil
    logger.debug("\nTrying to parse date: #{date_to_parse}...\n")

    #Make sure we are working with a string which isn't empty
    date_string = date_to_parse.to_s.strip
    return nil if date_string.empty?

    # Try a special case MM-YYYY (this is parsed wrong by Ruby)
    date = Date.strptime(date_string, "%m-%Y") rescue nil if date.nil?

    # Try a general parse (this covers most widely used date formats)
    parsed_date= ParseDate.parsedate(date_string) rescue nil if date.nil?
    unless parsed_date.nil? or parsed_date.compact.empty?
      #only continue if we found at least a 4-digit year
      unless parsed_date[0].nil? or parsed_date[0].to_s.size<4
        # Create date with parsed Year, Month, & Day if none are nil
        date = Date.new(parsed_date[0],parsed_date[1], parsed_date[2]) rescue nil unless parsed_date[1].nil? or parsed_date[2].nil?
        # Create date with parsed Year & Month if none are nil
        date = Date.new(parsed_date[0],parsed_date[1]) rescue nil unless parsed_date[1].nil?
        # Create date with just Year
        date = Date.new(parsed_date[0]) rescue nil
      end
    end

    # If our date is still nil, then Ruby is having trouble parsing this date.
    # So, let's clean it up a bit, and try some more possible formats
    if date.nil?
      # Remove any non-digits at end of string (since Ruby couldn't recognize them)
      # This allows us to handle rare formats like:
      #     "YYYY/MM/DD/other info" (e.g. "2008///Spring")
      date_string = date_string.sub(/\D*$/, '')

      #return immediately if we don't have at least a 4-digit year
      return nil if date_string.size<4

      # Try parsing abnormal date formats, which Ruby doesn't understand by default
      # (e.g. DD/MM/YYYY, MM-DD-YYYY)
      date = Date.strptime(date_string, "%d/%m/%Y") rescue nil if date.nil?
      date = Date.strptime(date_string, "%m-%d-%Y") rescue nil if date.nil?

      # Finally, as a last effort, just look for a year (e.g. "2008" or "Fall 2008")
      if date.nil?
        #try to parse out a year (i.e. look for 4 digits in a row)
        year = date_string.match(/\d{4}/)
        #take first matching "year", and make a date out of it
        date = Date.strptime(year[0], "%Y") rescue nil unless year.nil?
      end
    end

    unless date.nil?
      #return date in YYYY-MM-DD format
      logger.debug("Date parsed as: #{date.to_s}")
      return date.to_s
    else
      logger.debug("Could not parse this date!\n")
      return nil
    end
  end

  #If a given String is actually a ActiveSupport::Multibyte::Chars",
  #  return its value as a String (so that it will be saved to database as such)
  def chars_to_string(value)
    if value.is_a?(ActiveSupport::Multibyte::Chars)
      return value.to_s
    end

    return value
  end

end