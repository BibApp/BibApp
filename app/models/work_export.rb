class WorkExport
  require 'citeproc'
  attr_accessor :csl_file, :input, :input_filter, :input_content_type, :output, :formatter_type, :format_type
  attr_accessor :documents, :style, :formatter

  def initialize
    @input_filter_type = 'bibapp'
    @processor_type = 'text'
    @input_content_type = 'yaml'
    @format_type = 'bibliography'
    @formatter = 'xhtml'
    @output = 'stdout'
  end

  def drive_csl(format, input)
    @input = input
    csl_style(format)
    load_citations
    load_csl
    load_locale
    load_processor
    load_formatter

    @citations = do_format

    return @citations
  end

  #if needed in the future we can do something more complex than this
  def csl_style(format)
    @csl_file = format.downcase + '.csl'
  end

  def load_citations
    @input_filter = Bibapp::BibappInputFilter.new
    @input_filter.parse(@input, { :content_type => @input_content_type })
  end


  def load_csl
    @style = parser_from_csl_file(@csl_file).style
  end

  def parser_from_csl_file(csl)
    File.open(full_csl_file_path(csl)) do |f|
      Citeproc::CslParser.new(f)
    end
  end

  def full_csl_file_path(csl_file)
    File.join(Rails.root, 'public', 'csl_styles', csl_file)
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
    @formatter = Citeproc::XhtmlFormatter.new
  end


  def do_format
    nodes = @processor.process_bibliography(@input_filter, @style, @locale)
    results = @formatter.format(nodes)

    return results
  end

end