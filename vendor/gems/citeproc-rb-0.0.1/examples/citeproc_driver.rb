#! /usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

#  == Synopsis
#
# Example of how to use Citeproc-rb.
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
 

require 'citeproc'


class CiteprocDriver
  attr_accessor :csl, :input, :input_filter, :input_content_type, :output, :formatter_type, :format_type
  attr_accessor :documents, :style, :formatter

  def initialize
    @input_filter_type = 'csl'
    @processor_type = 'text'
    @input_content_type = 'yaml'
    @output = 'stdout'
  end


  def drive_csl
    process_args

    load_citations

    load_csl

    load_locale

    load_processor

    load_formatter

    do_format
  end


  def load_citations
    case @input_filter_type
    when "bibo", "bibliontology"
      @input_filter = Bibo::BiboInputFilter.new
    else
      @input_filter = CSL::CslInputFilter.new
    end
    @input_filter.parse(@input, { :content_type => @input_content_type })
  end


  def load_csl
    parser = Citeproc::CslParser.new(@csl)
    @style = parser.style
  end


  def load_locale
    if @locale_input
      parser = Citeproc::CslParser.new(@locale_input)
      @locale = parser.terms.locales.first if parser.terms
    end
  end


  def load_processor
    @processor = Citeproc::CslProcessor.new
  end


  def load_formatter
    case @format_type
    when "xhtml"
      @formatter = Citeproc::XhtmlFormatter.new
    else
      @formatter = Citeproc::BaseFormatter.new
    end
  end


  def do_format
    nodes = []
    if @format_type == "bibliography"
      nodes = @processor.process_bibliography(@input_filter, @style, @locale)
    elsif @format_type == "citation"
      nodes = @processor.process_citation(@input_filter, @style, @locale)
    else
      nodes = @processor.process_all(@input_filter, @style, @locale)
    end
    results = @formatter.format(nodes)
    if @output == "stdout"
      puts results
    else
      f = File.new(@output, "w+")
      f.write(results)
      f.close
    end
  end


  def process_args
    len = ARGV.length - 1
    0.upto len -1 do |i|
      arg = ARGV[i]
      case 
      when arg == '-c', arg == '--csl'
        @csl = ARGV[i + 1]
      when arg == '-i', arg == '--input'
        @input = ARGV[i + 1]
      when arg == '-if', arg == '--input-filter'
        @input_filter_type = ARGV[i + 1]
      when arg == '-ct', arg == '--content-type'
        @input_content_type = ARGV[i + 1]
      when arg == '-o', arg == '--output'
        @output = ARGV[i + 1]
      when arg == '-l', arg == '--locale'
        @locale_input = ARGV[i + 1]
      when arg == '-f', arg == '--formatter'
        @processor_type = ARGV[i + 1]
      when arg == '-ft', arg == '--format-type'
        @format_type = ARGV[i + 1]
      when arg == '-h', arg == '--help'
        print_help
      end
    end

    # Is there sufficient input?
    if !@input or !@csl
      print_help
    elsif !File.exists?(@input) 
      print_bad_file("Input", @input)
    elsif !File.exists?(@csl)
      print_bad_file("CSL", @csl)
    end
  end

  def print_help
    puts "Correct syntax: ./lib/citeproc.rb -i [the input file] -c [the CSL style definition] [optionally: -o [the output file] -if [the input filter] -ct [the input content type] -of [the output format]]"
    exit
  end

  def print_bad_file(type, file)
    puts "#{type} file: #{file} seems to be missing, or is inaccessible."
    exit
  end

  def print_type_error(type, msg)
    puts msg
    puts "Class received was instead: #{type}"
    exit
  end

end

# Provide a command-line interface to the Ruby Citeproc system
# Must have:
#  a) a YAML file for the bibliontology references
#  b) a CSL file for the formatting instructions
#  c) a output
#
if __FILE__ == $0
  driver =  CiteprocDriver.new
  driver.drive_csl
end
