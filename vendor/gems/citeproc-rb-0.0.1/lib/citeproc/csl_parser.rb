#! /usr/bin/env ruby
#  == Synopsis
#
# The CSL parser builds a CSL model from a file containing XML conforming to the 
# CSL RelaxNG schema.
# 
# Code usage: 
# parser = CSLParser.new(io or file)
# style = parser.style
# 
# Command line usage: 
# ./lib/csl_parser csl_file
#
#  == Author
#
#  Liam Magee
#
#  == Copyright
#
#  Copyright (c) 2007, Liam Magee.
#  Licensed under the same terms as Ruby - see http://www.ruby-lang.org/en/LICENSE.txt.
#
require 'rubygems'
require 'open-uri'
require 'rexml/document'
require 'builder'


module Citeproc
  class CslParser
    attr_reader :style, :terms
    
    def initialize(source)
      build(source)
    end
    
  
    # ---------- Private methods for parsing the CSL DOM -----------

    # Mixin for formatting types
  

    private
    def build(source)
      if source.kind_of?(String)
        @document = REXML::Document.new(open(source))
      elsif source.kind_of?(IO)
        @document = REXML::Document.new(source)
      end
      if @document.elements["style"]
        build_style
      elsif @document.elements["terms"]
        build_terms
      end
    end
    
    def build_style
      style_node = @document.elements["style"]
      @style = Style.new(
          style_class = attr(style_node, :class),
          lang = attr(style_node, :lang, 'xml'),
          info = build_info(style_node),
          terms = build_terms(style_node),
          macros = build_macros(style_node),
          citation = build_citation(style_node),
          bibliography = build_bibliography(style_node)
        )
    end
    
    def build_info(style_node)
      info_node = style_node.elements["info"]
      info = Info.new(
        id = text(info_node, :id),
        title = info_text(info_node, :title),
        updated = time(info_node, :updated),
        authors = build_authors(info_node),
        categories = build_categories(info_node),
        contributors = build_contributors(info_node),
        published = time(info_node, :published),
        links = build_links(info_node),
        rights = info_text(info_node, :rights),
        source = text(info_node, :source),
        summary = info_text(info_node, :summary)
      )
    end
    
    def build_authors(node)
      authors = []
      node.elements.each("author") do |author|
        authors << Author.new(
          text(author, :name),
          text(author, :email),
          text(author, :uri)
        )
      end
      authors
    end
    
    def build_categories(node)
      categories = []
      node.elements.each("category") do |category|
        categories << Category.new(
          attr(category, :term),
          attr(category, :scheme),
          attr(category, :label)
        )
      end
      categories
    end
        
    def build_contributors(node)
      contributors = []
      node.elements.each("contributor") do |contributor|
        contributors << Contributor.new(
          text(contributor, :name),
          text(contributor, :email),
          text(contributor, :uri)
        )
      end
      contributors
    end
        
    def build_links(node)
      links = []
      node.elements.each("link") do |link|
        links << attr(link, :href)
      end
      links
    end
    
    def build_terms(node = nil)
      terms_node = @document.elements["terms"] if !node
      if terms_node
        @terms = Terms.new(
          locales = build_locales(terms_node)
        )
      end
      @terms
    end
    
    def build_locales(node)
      locales = []
      node.elements.each("locale") do |locale|
        locales << Locale.new(
          language = attr(locale, "xml:lang"),
          terms = build_individual_terms(locale)
        )
      end
      locales
    end
    
    def build_individual_terms(node)
      terms = []
      node.elements.each("term") do |term|
        if term.elements["single"] or term.elements["multiple"]
          t = CompoundTerm.new(
            form = attr(term, "form"),
            name = attr(term, "name"),
            include_period = attr(term, "include_period")
          )
          # TODO: Can there be multiple single and multiple nodes in practice, as per
          # the CSL spec?
          t.single = text(term.elements["single"])
          t.multiple = text(term.elements["multiple"])
          terms << t
        else
          terms << SimpleTerm.new(
            form = attr(term, "form"),
            name = attr(term, "name"),
            include_period = attr(term, "include_period"),
            text = text(term)
          )
        end
      end
      terms
    end

    
    def build_macros(node)
      macros = []
      node.elements.each("macro") do |m|
        macro = Macro.new(
          name = attr(m, :name)
        )
        build_elements(m, macro)
        macros << macro
      end
      macros
    end
    
    
    def build_citation(node)
      citation_node = node.elements["citation"]
      citation = CitationContext.new(
        options = build_options(citation_node),
        sort = build_sort(citation_node),
        layout = build_layout(citation_node)
      )
      citation
    end
    
    def build_bibliography(node)
      bibliography_node = node.elements["bibliography"]
			if bibliography_node
		    bibliography = BibliographyContext.new(
		      options = build_options(bibliography_node),
		      sort = build_sort(bibliography_node),
		      layout = build_layout(bibliography_node)
		    )
			end
      bibliography
    end
    
    
    def build_citation(node)
      citation_node = node.elements["citation"]
			if citation_node
		    citation = CitationContext.new(
		      options = build_options(citation_node),
		      sort = build_sort(citation_node),
		      layout = build_layout(citation_node)
		    )
			end
      citation
    end
    
   
    # Simplification of option model
    def build_options(node)
      options = {}
      node.elements.each("option") do |option|
        options[attr(option, :name)] = attr(option, :value)
      end
      options
    end
    
    def build_sort(node)
      keys = []
      sort = Sort.new
      node.elements.each("sort/key") do |key_node|
        key = build_text(key_node)
        sort << key
        
#        value = key.attribute('variable') ? attr(key, :variable) : 
#		(key.attribute('macro')	? attr(key, :macro) : attr(key, :sort))
#        type = key.attribute('variable') ? 'variable' : 'macro'
#        keys << SortKey.new(type, value)
      end
      sort
    end
    
    def build_layout(node)  
      layout_node = node.elements["layout"]
      if layout_node
        layout = Layout.new(
            formatting = build_formatting(layout_node),
            delimiters = build_delimiters(layout_node)
        )
        build_elements(layout_node, layout)
      end
      layout
    end

    
    # 'obj' should be some instance of GroupingElement
    def build_elements(node, obj)
      node.elements.each do |e|
        case
        when e.name == "names"
          obj << (build_names(e))
        when e.name == "date"
          obj << (build_date(e))
        when e.name == "label"
          obj << (build_label(e))
        when e.name == "text"
          obj << (build_text(e))
        when e.name == "group"
          obj << (build_group(e))
        when e.name == "choose"
          obj << (build_conditions(e))
        end
      end
    end
    
    def build_names(node)
      name = node.elements["name"] 
      # if this a full Names node?
      if name
        names = Names.new(
            formatting = build_formatting(node),
            delimiters = build_delimiters(node),
            variable = attr(node, :variable)
        )
        if node.elements["name"] 
          name = node.elements["name"] 
          names.name = Name.new(
            formatting = build_formatting(name),
            delimiters = build_delimiters(name),
            form = attr(name, :form),
            _and = attr(name, :and),
            delimiter_precedes_last = attr(name, 'delimiter-precedes-last'),
            name_as_sort_order = attr(name, 'name-as-sort-order'),
            sort_separator = attr(name, 'sort-separator'),
            initialize_with = attr(name, 'initialize-with')
          )
        end
        node.elements.each("label") do |label|
          names.add_label( NameLabel.new(
            formatting = build_formatting(label),
            include_period = attr(label, :include_period),
            form = attr(label, :form)
          ) )
        end
        if node.elements["substitute"]
          names.substitute = build_substitute(node.elements["substitute"])
        end
      else
        names = ShortNames.new(
            formatting = build_formatting(node),
            delimiters = build_delimiters(node),
            variable = attr(node, :variable)
        )
      end
      names
    end
    
    def build_substitute(node)
      substitute = Substitute.new
      build_elements(node, substitute)
      substitute
    end
    
    def build_date(node)
      date = Date.new(
          formatting = build_formatting(node),
          delimiters = build_delimiters(node),
          variable = attr(node, :variable)
        )
      node.elements.each("date-part") do |dp|
        date << DatePart.new(
          formatting = build_formatting(dp),
          name = attr(dp, :name),
          form = attr(dp, :form)
        )
      end
      date
    end
    
    
    def build_label(node)
      label = Label.new(
          formatting = build_formatting(node),
          include_period = attr(node, 'include-period'),
          form = attr(node, :form),
          variable = attr(node, :variable)
      )
      label
    end
    
    
    def build_text(node)
      case
      when attr(node, :variable)
        text = VariableText.new(
          formatting = build_formatting(node),
          delimiters = build_delimiters(node),
          variable = attr(node, :variable)
        )
      when attr(node, :macro)
        text = MacroText.new(
          formatting = build_formatting(node),
          macro = attr(node, :macro)
        )
      when attr(node, :term)
        text = TermText.new(
          formatting = build_formatting(node),
          term = attr(node, :term)
        )
      when attr(node, :value)
        text = ValueText.new(
          formatting = build_formatting(node),
          value = attr(node, :value)
        )
      end
      text
    end
    
    def build_group(node)
      group = Group.new(
          formatting = build_formatting(node),
          delimiters = build_delimiters(node),
          class_name = attr(node, :class)
      )
      build_elements(node, group)
      group
    end
    
    def build_conditions(choose_node)
      conditions = ConditionGroup.new
      conditions << build_condition(choose_node.elements["if"])
      choose_node.elements.each("else-if") do |c|
        conditions << build_condition(c)
      end
      end_node = choose_node.elements["else"]
      conditions << build_condition(end_node, false) if end_node
      conditions
    end
    
    def build_condition(node, include_attributes = true)
      condition = Condition.new
      attrs = [:type, :variable, :position, :disambiguate, :locator, :match]
      attrs.each do |a|
        condition.send("#{a.to_s}=", attr(node, a))
      end if include_attributes
      build_elements(node, condition)
      condition
    end

    
    def build_formatting(node)
      formatting_options = {}
      Formatting::FORMATTING_TERMS.each do |ft|
        formatting_options[ft] = attr(node, ft)
      end
      formatting_options
    end
    
    def build_delimiters(node)
      delimiter_options = {}
      Delimiter::DELIMITER_TERMS.each do |dt|
        delimiter_options[dt] = attr(node, dt)
      end
      delimiter_options
    end
    
    # Shortcut methods for extracting values from the DOM
    def attr(node, attribute_name, namespace = nil)
      attr = (attribute_name.is_a? Symbol) ? attribute_name.to_s : attribute_name
      node.attribute(attr, namespace).value if node.attribute(attr) 
    end

    def text(node, child_node_name = nil)
      if child_node_name
        child = (child_node_name.is_a? Symbol) ? child_node_name.to_s : child_node_name
        # What if there are multiple children here?
        node.elements[child].text if node.elements[child] and node.elements[child].size == 1
      else
        node.text
      end
    end

    def array(node, child_node_name)
      child = (child_node_name.is_a? Symbol) ? child_node_name.to_s : child_node_name
      results = []
      node.elements[child].each {|c| results << c } if node.elements[child]
      results
    end
    
    def time(node, child_node_name)
      require 'time'
      t = text(node, child_node_name)
      Time.parse(t) if t
    end

    def info_text(node, child_node_name)
      text = text(node, child_node_name)
      lang = attr(node, "lang", "xml")
      InfoText.new(text, lang) if text
    end
  end
end

# Provide a command-line interface to the parser
if ($FILE == $0)
  if $1
    file = $1
    parser = CSL::CslParser.new(file)
  end
end
