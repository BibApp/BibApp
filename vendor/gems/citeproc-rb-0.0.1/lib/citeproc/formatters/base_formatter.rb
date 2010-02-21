#  == Synopsis
#
#  Formats a series of document references according to a given CSL style.
#
#  == Author
#
#  Liam Magee
#
#  == Copyright
#
#  Copyright (c) 2008, Liam Magee.
#  Licensed under the same terms as Ruby - see http://www.ruby-lang.org/en/LICENSE.txt.
#
 
module Citeproc
  
  class BaseFormatter
    def format(node)
      result = ''
      if node.is_a?(Array)
        node.each do |n|
          tmp = format(n)
          if tmp
            result << tmp
            result << "\n"
          end
        end
      elsif node
        a = ''
        b = []
        a << delimit_node(node.element, node.results)
        node.children.compact.each{|c| b << format(c) } 
        a << delimit_node(node.element, b)

        result = format_node(node.element, a)
      end
      result
    end
    

  private

    def format_node(formatter, text)
      return text if !formatter.is_a?(Formatting)
      return '' if !text or text.empty?
      results = ''
      
      results << formatter.prefix if formatter.prefix and !text.start_with?(formatter.prefix)
      results << '"' if formatter.quotes
 
      # Add the actual text
      results << format_text(text, formatter.text_case)
      
      results << '"' if formatter.quotes
      results << formatter.suffix if formatter.suffix and !text.end_with?(formatter.suffix)

      results
    end

    # The following performs direct text changes - should be toggled off for mark-up?
    #lowercase, uppercase, capitalize-first, capitalize-all, title, sentence.
    def format_text(text, textcase)
      case textcase
      when "lowercase"
        text.downcase!
      when "uppercase"
        text.upcase!
      when "capitalize-first"
        text[0] = text[0..0].upcase
        # Need to separate out these cases
      when "capitalize-all", "title", "sentence"
        # Tries a simple exclusion of common words from title capitalisation
        # Suffers from a lack of internationalisation...
        text = text.split(' ').collect{|t| 
          t.capitalize unless t == text.split(' ')[0] and ['and', 'the', 'a', 'of', 'by', 'to', 'at'].include?(t) 
        }.join(' ')
      end
      text
    end
    
    
    def delimit_node(node, elements)
      results = ""
      clean = elements.compact.reject{|e| e if e.to_s.strip.empty?}
      len = clean.length - 1
      delim = node.is_a?(Delimiter)
      (0..len).each do |i|
        case i
        when 0
        # Do nothing
        when len 
          if delim
            if node.delimiter_precedes_last and node.delimiter_precedes_last == "never"
              # Still do nothing
            elsif delim and node.delimiter
              results << node.delimiter
            end
            if node.and == "text"
              results.strip!
              results << " and "
            elsif node.and == "symbol"
              results.strip!
              results << " & "
            end
          end
        else
          results << node.delimiter if delim and node.delimiter
        end
        # Finally, add the content
        results << clean[i].to_s
      end
      results
    end
  end
end
