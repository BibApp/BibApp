require 'haml/helpers/action_view_mods'
require 'haml/helpers/action_view_extensions'

module Haml
  # This module contains various helpful methods to make it easier to do
  # various tasks. Haml::Helpers is automatically included in the context
  # that a Haml template is parsed in, so all these methods are at your
  # disposal from within the template.
  module Helpers
    self.extend self

    @@action_view_defined = defined?(ActionView)
    @@force_no_action_view = false

    # Returns whether or not ActionView is installed on the system.
    def self.action_view?
      @@action_view_defined
    end

    # Isolates the whitespace-sensitive tags in the string and uses preserve
    # to convert any endlines inside them into HTML entities for endlines.
    def find_and_preserve(input)
      input = input.to_s
      input.scan(/<(textarea|code|pre)[^>]*>(.*?)<\/\1>/im) do |tag, contents|
        input = input.gsub(contents, preserve(contents))
      end
      input
    end

    # Takes any string, finds all the endlines and converts them to
    # HTML entities for endlines so they'll render correctly in
    # whitespace-sensitive tags without screwing up the indentation.
    def preserve(input)      
      input.gsub(/\n/, '&#x000A;').gsub(/\r/, '')
    end

    alias_method :flatten, :preserve

    # Takes an Enumerable object and a block
    # and iterates over the object,
    # yielding each element to a Haml block
    # and putting the result into <tt><li></tt> elements.
    # This creates a list of the results of the block.
    # For example:
    #
    #   = list_of([['hello'], ['yall']]) do |i|
    #     = i[0]
    #
    # Produces:
    #
    #   <li>hello</li>
    #   <li>yall</li>
    #
    # And
    #
    #   = list_of({:title => 'All the stuff', :description => 'A book about all the stuff.'}) do |key, val|
    #     %h3= key.humanize
    #     %p= val
    #
    # Produces:
    #
    #   <li>
    #     <h3>Title</h3>
    #     <p>All the stuff</p>
    #   </li>
    #   <li>
    #     <h3>Description</h3>
    #     <p>A book about all the stuff.</p>
    #   </li>
    #
    def list_of(array, &block) # :yields: item
      to_return = array.collect do |i|
        result = capture_haml(i, &block)
        
        if result.count("\n") > 1
          result.gsub!("\n", "\n  ")
          result = "\n  #{result.strip}\n"
        else
          result.strip!
        end
        
        "<li>#{result}</li>"
      end
      to_return.join("\n")
    end

    # Returns a hash containing default assignments for the xmlns and xml:lang
    # attributes of the <tt>html</tt> HTML element.
    # It also takes an optional argument for the value of xml:lang and lang,
    # which defaults to 'en-US'.
    # For example,
    #
    #   %html{html_attrs}
    #
    # becomes
    #
    #   <html xmlns='http://www.w3.org/1999/xhtml' xml:lang='en-US' lang='en-US'>
    #
    def html_attrs(lang = 'en-US')
      {:xmlns => "http://www.w3.org/1999/xhtml", 'xml:lang' => lang, :lang => lang}
    end

    # Increments the number of tabs the buffer automatically adds
    # to the lines of the template.
    # For example:
    #
    #   %h1 foo
    #   - tab_up
    #   %p bar
    #   - tab_down
    #   %strong baz
    #
    # Produces:
    #
    #   <h1>foo</h1>
    #     <p>bar</p>
    #   <strong>baz</strong>
    #
    def tab_up(i = 1)
      buffer.tabulation += i
    end

    # Increments the number of tabs the buffer automatically adds
    # to the lines of the template.
    #
    # See tab_up.
    def tab_down(i = 1)
      buffer.tabulation -= i
    end
    
    # Surrounds the given block of Haml code with the given characters,
    # with no whitespace in between.
    # For example:
    #
    #   = surround '(', ')' do
    #     %a{:href => "food"} chicken
    #
    # Produces:
    #
    #   (<a href='food'>chicken</a>)
    #
    # and
    #
    #   = surround '*' do
    #     %strong angry
    #
    # Produces:
    #
    #   *<strong>angry</strong>*
    #
    def surround(front, back = nil, &block)
      back ||= front
      output = capture_haml(&block)
      
      "#{front}#{output.chomp}#{back}\n"
    end
    
    # Prepends the given character to the beginning of the Haml block,
    # with no whitespace between.
    # For example:
    #
    #   = precede '*' do
    #     %span.small Not really
    #
    # Produces:
    #
    #   *<span class='small'>Not really</span>
    #
    def precede(char, &block)
      "#{char}#{capture_haml(&block).chomp}\n"
    end
    
    # Appends the given character to the end of the Haml block,
    # with no whitespace between.
    # For example:
    #
    #   click
    #   = succeed '.' do
    #     %a{:href=>"thing"} here
    #
    # Produces:
    #
    #   click
    #   <a href='thing'>here</a>.
    #
    def succeed(char, &block)
      "#{capture_haml(&block).chomp}#{char}\n"
    end
    
    # Captures the result of the given block of Haml code,
    # gets rid of the excess indentation,
    # and returns it as a string.
    # For example, after the following,
    #
    #   .foo
    #     - foo = capture_haml(13) do |a|
    #       %p= a
    #
    # the local variable <tt>foo</tt> would be assigned to "<p>13</p>\n".
    #
    def capture_haml(*args, &block)
      capture_haml_with_buffer(buffer.buffer, *args, &block)
    end

    # Outputs text directly to the Haml buffer, with the proper tabulation
    def puts(text = "")
      buffer.buffer << ('  ' * buffer.tabulation) << text.to_s << "\n"
      nil
    end

    #
    # call-seq:
    #   open(name, attributes = {}) {...}
    #   open(name, text, attributes = {}) {...}
    #
    # Creates an HTML tag with the given name and optionally text and attributes.
    # Can take a block that will be executed
    # between when the opening and closing tags are output.
    # If the block is a Haml block or outputs text using puts,
    # the text will be properly indented.
    # 
    # For example,
    #
    #   open :table do
    #     open :tr do
    #       open :td, {:class => 'cell'} do
    #         open :strong, "strong!"
    #         puts "data"
    #       end
    #       open :td do
    #         puts "more_data"
    #       end
    #     end
    #   end
    #
    # outputs
    #
    #   <table>
    #     <tr>
    #       <td class='cell'>
    #         <strong>
    #           strong!
    #         </strong>
    #         data
    #       </td>
    #       <td>
    #         more_data
    #       </td>
    #     </tr>
    #   </table>
    #
    def open(name, attributes = {}, alt_atts = {}, &block)
      text = nil
      if attributes.is_a? String
        text = attributes
        attributes = alt_atts
      end

      puts "<#{name}#{buffer.build_attributes(attributes)}>"
      tab_up
        # Print out either the text (using push_text) or call the block and add an endline
        if text
          puts(text)
        elsif block
          block.call
        end
      tab_down
      puts "</#{name}>"
      nil
    end
    
    private

    # Gets a reference to the current Haml::Buffer object.
    def buffer
      @haml_stack[-1]
    end
    
    # Gives a proc the same local "_hamlout" and "_erbout" variables
    # that the current template has.
    def bind_proc(&proc)
      _hamlout = buffer
      _erbout = _hamlout.buffer
      proc { |*args| proc.call(*args) }
    end
    
    # Performs the function of capture_haml, assuming <tt>local_buffer</tt>
    # is where the output of block goes.
    def capture_haml_with_buffer(local_buffer, *args, &block)
      position = local_buffer.length
      
      block.call *args
      
      captured = local_buffer.slice!(position..-1)
      
      min_tabs = nil
      captured.each do |line|
        tabs = line.index(/[^ ]/)
        min_tabs ||= tabs
        min_tabs = min_tabs > tabs ? tabs : min_tabs
      end
      
      result = captured.map do |line|
        line[min_tabs..-1]
      end
      result.to_s
    end

    # Returns whether or not the current template is a Haml template.
    # 
    # This function, unlike other Haml::Helpers functions,
    # also works in other ActionView templates,
    # where it will always return false.
    def is_haml?
      @haml_is_haml
    end
    
    include ActionViewExtensions if self.const_defined? "ActionViewExtensions"
  end
end

module ActionView
  class Base # :nodoc:
    def is_haml?
      false
    end
  end
end
