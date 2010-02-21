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
  
  class XhtmlFormatter
    
    def format(node)
      result = ''
      if node.is_a?(Array)
        node.each do |n|
          tmp = format(n)
          if tmp
            result << '<div class="work">'
            result << tmp
            result << "</div>\n"
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
			
      text_content = format_text(text, formatter.text_case)
      already_spanned = text_content.starts_with?("<span") and text_content.ends_with?("</span>")

      
      if !already_spanned
        # Note: these attributes should only apply to certain kinds of formatters, i.e. those based on mark-up 
        results << '<span' # Could be block/inline/div - needs to be conditional on both 'display' attribute and mark-up variant (XHTML, XSL-FO)
        style = ''			
        style << "font-family: #{formatter.font_family}; " if formatter.font_family
        style << "font-style: #{formatter.font_style}; " if formatter.font_style
        style << "font-variant: #{formatter.font_variant}; " if formatter.font_variant
        style << "font-weight: #{formatter.font_weight}; " if formatter.font_weight
        style << "text-decoration: #{formatter.text_decoration}; " if formatter.text_decoration
        style << "text-transform: #{formatter.text_transform}; " if formatter.text_transform
        style << "vertical-align: #{formatter.vertical_align}; " if formatter.vertical_align
        style << "enforce-case: #{formatter.enforce_case}; " if formatter.enforce_case
        display = formatter.formatting[:display.to_s]
        style << "display: #{display}; " if display
        style << "quotes: #{formatter.quotes}; " if formatter.quotes 
        results << %Q' style="#{style}"' if !style.empty?
        results << ">"
      end

      results << formatter.prefix if formatter.prefix and !text.start_with?(formatter.prefix)
      results << '"' if formatter.quotes
 
      # Add the actual text
      results << text_content
      
      results << '"' if formatter.quotes
      results << formatter.suffix if formatter.suffix and !text.end_with?(formatter.suffix)
      
			if !already_spanned
	      results << "</span>"
			end

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
              results << " &amp; "
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
