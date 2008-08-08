class CitationExport
  require 'citeproc'
  attr_accessor :csl, :input, :input_filter, :input_content_type, :output, :formatter_type, :format_type
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
    @input = input.collect{|c| Citation.find(c['pk_i'])}
    csl_style(format)
    load_citations
    load_csl
    load_locale
    load_processor
    load_formatter

    @citations = do_format
    
    return @citations
  end

  def csl_style(format)
    case format.downcase
    when "apa"
      @csl = "http://www.zotero.org/styles/apa"
    when "ieee"
      @csl = "http://www.zotero.org/styles/ieee"
    end
  end

  def load_citations
    @input_filter = Bibapp::BibappInputFilter.new
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
    @formatter = Citeproc::XhtmlFormatter.new
  end


  def do_format
    nodes = []
    nodes = @processor.process_bibliography(@input_filter, @style, @locale)
    results = @formatter.format(nodes)

    return results
  end

end