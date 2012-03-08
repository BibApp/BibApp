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
      next unless r_key and self.value_translators[r_key]

      # Perform any translation of value(s) (using our value translators)
      r_val = self.value_translators[key].call(values)

      #if the value is a Hash (i.e. responds to "keys")
      if r_val.respond_to?(:keys)
        #Save each value separately in our final hash
        #(This covers cases where we are parsing out two or more properties
        # from a single field, e.g. parsing start & end pages out of a "pages" field)
        r_val.each do |s_key, s_val|
          r_hash[s_key] = s_val
        end
        #Else if our final hash already has this key within it
      elsif r_hash.has_key?(r_key)
        #add this value to existing key (and create an array of values)
        r_hash[r_key] = Array.wrap(r_hash[r_key]) << r_val
      else #by default, just copy our key & value to final hash
        r_hash[r_key] = r_val
      end
    end

    #if not already taken care of, copy the entire citation into :original_data
    r_hash[:original_data] ||= parsed_citation.properties[:original_data].to_s

    # TODO: this is ugly!
    # Hack for RefWorks export of Conference Proceedings:
    # RefWorks XML uses <ed> (:edition) for Conference Location
    # RefWorks RIS uses :vl
    if r_hash[:klass][0].to_s == "ConferencePaper"
      case parsed_citation.citation_type.to_s == "refworks_xml"
        when "refworks_xml"
          r_hash[:location] = parsed_citation.properties[:edition]
          r_hash[:edition] = nil
        when "ris"
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
      if value and value.respond_to?(:flatten)
        value = value.flatten
      end

      #remove keys which have nil or empty values
      #This removes empty Arrays, Hashes and Strings
      if value.blank? or (value.is_a?(Array) and value[0].blank?)
        hash.delete(key)
        next
      end

      #If we have an Array of Strings (or Unicode Strings) with only a single value,
      # just return the first String as the value
      if value.is_a?(Array) and value.size==1 and value[0].acts_like?(:string)
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
      #TODO I'm not sure this is doing what the original author intended when value is a Hash!
      if value.is_a?(Array) or value.is_a?(Hash)
        value = value.collect { |v| chars_to_string(v) }
      end

      #save cleaned value
      hash[key] = value
    end
    return hash
  end

  # Global method to parse out publication dates
  # (Can be overriden by individual importers, as necessary)
  def publication_date_parse(publication_date)
    parse_date(publication_date).reverse_merge(:publication_date_year => nil, :publication_date_month => nil, :publication_date_day => nil)
  end


  # Parse a date out of a string, and returns in YYYY-MM-DD format
  # (returns nil if date cannot be parsed)
  def parse_date(date_to_parse, stripped = nil)

    date_string = date_to_parse.to_s.strip
    return {} if date_string.empty?
    return {} if stripped and date_string.size < 4

    #try a variety of ways of parsing the date string, including stripping the date of non-numbers at the end and
    #recursively calling this function
    date = parse_date_mm_yyyy(date_string) || parse_date_parsedate(date_string) || parse_date_dd_mm_yyyy(date_string) ||
        parse_date_mm_dd_yyyy(date_string) || (!stripped and parse_date(date_string.sub(/\D*$/, ''), true)) || parse_date_year(date_string)

    if date
      return date
    else
      logger.debug("Could not parse this date!\n")
      return {}
    end
  end

  def parse_date_parsedate(date_string)
    parsed_date = ParseDate.parsedate(date_string) rescue nil
    return nil unless parsed_date and parsed_date[0].present? and parsed_date[0].to_s.size >=4
    year = parsed_date[0]
    month = parsed_date[1]
    day = parsed_date[2]
    begin
      #make sure that we have a valid date returned - note that this will, incorrectly, parse something like 21/05/2001
      #to have a month of 21. This code checks for that.
      date = Date.new(year, month || 1, day || 1)
      return {:publication_date_year => year, :publication_date_month => month, :publication_date_day => day}
    rescue
      return nil
    end
  end

  def parse_date_mm_yyyy(date_string)
    #This _will_ parse something like '02-19-1977', albeit incorrectly, so make sure it doesn't get that chance
    return nil if date_string.match(/-.*-/)
    date_strptime_parse_generic(date_string, "%m-%Y", :year, :month)
  end

  def parse_date_dd_mm_yyyy(date_string)
    date_strptime_parse_generic(date_string, "%d/%m/%Y", :year, :month, :day)
  end

  def parse_date_mm_dd_yyyy(date_string)
    date_strptime_parse_generic(date_string, "%m-%d-%Y", :year, :month, :day)
  end

  def parse_date_year(date_string)
    date_strptime_parse_generic(date_string.match(/\d{4}/)[0], "%Y", :year)
  end

  def date_strptime_parse_generic(date_string, format_string, *returned_parts)
    return nil if date_string.blank?
    date = Date.strptime(date_string, format_string)
    returned_parts.each_with_object({}) { |part, hash| hash[:"publication_date_#{part}"] = date.send(part) }
  rescue
    return nil
  end

  #If a given String is actually a ActiveSupport::Multibyte::Chars",
  #  return its value as a String (so that it will be saved to database as such)
  def chars_to_string(value)
    value.acts_like?(:string) ? value.to_s : value
  end

  def strip_line_breaks(value)
    value.mb_chars.squish
  end

  def remove_trailing_period(value)
    value.gsub(/\.(\s*)$/, "")
  end

  #Check each source key (in order) until one is found with hash[source_key] present
  #If one is found then make hash[target_key] = hash[source_key]
  #If not do not change hash[target_key]
  #In any case, delete each of the source keys from the hash
  def prioritize(hash, target_key, *source_keys)
    matching_key = source_keys.detect { |key| hash[key] }
    hash[target_key] = hash[matching_key] if matching_key
    source_keys.each { |key| hash.delete(key) }
  end

end