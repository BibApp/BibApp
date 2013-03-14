#
# Base XML format parser
#
# Provides basic utilities that any XML-based
# parser would want access to.
#
#
class BaseXmlParser < CitationParser

  def initialize()
    super
  end

  #Decode any XML entities after they've been parsed into a Hash.
  #  For example, this performs the following translations:
  #    &apos; => '
  #    &amp; => &
  #    &quot; => "
  #    &gt; => >
  #    &lt; => <
  def decode_xml_entities(props)
    coder = HTMLEntities.new

    #decode XML entities in any value
    props.each do |key, value|
      next if key == :original_data #never decode the original citation...keep it as is!

      #Determine whether we are cleaning arrays or strings
      if value.present?
        case value
          when Array
            value.collect! { |v| coder.decode(v) }
          when String
            props[key] = coder.decode(value)
        end
      end
    end

    return props
  end
end