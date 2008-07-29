#  == Synopsis
#
# Defines the CSL object model, the core of the Ruby Citeproc system.
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
 
module Citeproc
  
  # ---------- Modules -----------
  
  # Mixin for formatting types
  module Formatting
    FORMATTING_TERMS = [
        'prefix', 'suffix', 'font-family', 'font-style', 'font-variant', 'font-weight',
        'text-decoration', 'text-transform', 'text-case', 'vertical-align', 'enforce-case', 
        'display', 'quotes'
        ]
    attr_accessor :formatting
    
    # Careful if using multiple mixins - other modules may use this too.
    # How to delegate to other method_missing methods?
    def method_missing(name, *args)
      # Is a setter method?
      n = name.to_s.gsub('_', '-')
      if args and n.ends_with?('=')
        formatting[n.sub('=', '')] = args
      elsif formatting.has_key?(n)
        formatting[n]
      else
				''
       #raise NoMethodError
      end
    end
  end
  
  # Mixin for delimiter types
  module Delimiter
    DELIMITER_TERMS = [
        'delimiter', 'delimiter-precedes-last'
        ]
    attr_accessor :delimiters

    # These methods are used since the method_missing method won't be called if the Formatting
    # module takes precedence. 
    # TODO: Find a better way of handling this (a FormatterDelimiter module which overrides method_missing?)
    def delimiter
      delimiters[DELIMITER_TERMS[0]]
    end
    
    def delimiter=(value)
      delimiters[DELIMITER_TERMS[0]] = value
    end
    
    def delimiter_precedes_last
      delimiters[DELIMITER_TERMS[1]]
    end
    
    def delimiter_precedes_last=(value)
      delimiters[DELIMITER_TERMS[1]] = value
    end

  end

  
  
  
  
  # ---------- Classes -----------

  
  # ---------- Style -----------

  class Style
    attr_accessor :class, :lang, :info, :terms, :macros, :citation, :bibliography

    def initialize(style_class = 'in-text', lang = 'en', info = nil, terms = nil, macros = nil, citation = nil, bibliography = nil)
      @style_class = style_class
      @lang = lang
      @info = info
      @terms = terms
      @macros = macros
      @citation = citation
      @bibliography = bibliography
    end
    
    def add_macro macro
      @macros = [] if !@macros
      @macros << macro
    end
  end

  

  # ---------- Info classes -----------
  
  class Info
    attr_accessor :authors, :categories, :contributors, :id, :links, :published, :rights, :source, :summary, :title, :updated

    def initialize(id = nil, title = nil, updated = nil, authors = nil, categories = nil, contributors = nil, published = nil, links = nil, rights = nil, source = nil, summary = nil)
      @id = id
      @title = title
      @updated = updated
      @authors = authors ? authors : []
      @categories = categories ? categories : []
      @contributors = contributors ? contributors : []
      @published = published
      @links = links ? links : []
      @rights = rights
      @source = source
      @summary = summary
    end
  end

  
  # Handles CSL strings with language attributes
  class InfoText
    attr_accessor :text, :language

    def initialize(text = nil, language = 'en')
      @text = text
      @language = language
    end
  end

  class Agent
    attr_accessor :name, :email, :uri
    def initialize(name = nil, email = nil, uri = nil)
      @name = name
      @email = email
      @uri = uri
    end
  end
  
  class Author < Agent
    def initialize(name = nil, email = nil, uri = nil)
      super
    end
  end
  
  class Contributor < Agent
    def initialize(name = nil, email = nil, uri = nil)
      super
    end
  end

  
  class Category 
     INFO_FIELDS = [
      "anthropology", "biology", "botany", "chemistry", "engineering", "generic-base",
      "geography", "geology", "history", "literature", "philosophy", "psychology", 
      "sociology", "political_science", "zoology" #, info-categories.extension
      ]
    INFO_CLASSES = ["author-date", "numeric", "label", "note", "in-text"]

    attr_accessor :term, :scheme, :label
    def initialize(term = nil, scheme = nil, label = nil)
      @term = term
      @scheme = scheme
      @label = label
    end
    
    def is_standard_field?
      INFO_FIELDS.include?(term)
    end
    
    def is_standard_class?
      INFO_CLASSES.include?(term)
    end
  end  

  
  
  class GroupingElement
    attr_accessor :elements
    attr_reader :names, :labels, :dates, :texts, :groups, :conditionals

    def initialize
      @elements = []
      @names = []
      @labels = []
      @dates = []
      @texts = []
      @groups = []
      @conditionals = []
    end
    
    def add_element(element)
      @elements << element
      case 
      when element.kind_of?(Names)
        @names << element
      when element.kind_of?(Date)
        @dates << element
      when element.kind_of?(Label)
        @labels << element
      when element.kind_of?(Text)
        @texts << element
      when element.kind_of?(Group)
        @groups << element
      when element.kind_of?(ConditionGroup)
        @conditionals << element
      end
    end

    alias << add_element
  end

  

  # ---------- Term classes -----------
  
  class Terms 
    attr_accessor :locales

    def initialize(locales = nil)
      @locales = locales ? locales : []
    end
    
    def add_locale(locale)
      @locales << locale
    end
    
    alias << add_locale
  end
  
  
  class Locale
    attr_accessor :language, :terms

    def initialize(language = nil, terms = nil)
      @language = language
      @terms = terms ? terms : []
    end

    
    def add_term(term)
      @terms << term
    end

    
    def term_text(variable, form = nil, singular = true)
      @terms.each do |term|
        if variable == term.name
          if !form or form == term.form
            if term.kind_of? CompoundTerm
              return (singular ? term.single : term.multiple)
            else
              return term.text
            end
          end
        end
      end
      nil
    end

    alias << add_term
  end
  
  class Term
    attr_accessor :form, :name, :include_period

    def initialize(form = nil, name = nil, include_period = nil)
      @form = form
      @name = name
      @include_period = include_period
    end
  end
  
  # Redundant?
  class SimpleTerm < Term
    attr_accessor :text

    def initialize(form = nil, name = nil, include_period = nil, text = nil)
      super(form, name, include_period)
      @text = text
    end

    alias value text
  end
  
  # Redundant?
  class CompoundTerm < Term
    attr_accessor :single, :multiple

    def initialize(form = nil, name = nil, include_period = nil, single = nil, multiple = nil)
      super(form, name, include_period)
      @single = single
      @multiple = multiple
    end
  end

  

  # ---------- Macro classes -----------
  
  class Macro < GroupingElement
    attr_accessor :name
    
    def initialize(name)
      super()
      @name = name
    end
  end

  

  # ---------- Context (Citation and Bibliography) classes -----------
  
  class Context
    attr_accessor :options, :sort, :layout
    def initialize(options = nil, sort = nil, layout = nil)
      @options = options
      @sort = sort
      @layout = layout
    end
    
    def option(name)
      options[name]
    end
    
    
    # Careful if using multiple mixins - other modules may use this too.
    # How to delegate to other method_missing methods?
    def method_missing(name, *args)
      # Is a setter method?
      n = name.to_s.gsub('_', '-')
      if args and n.index('=') == n.length - 1
        options[n.sub('=', '')] = args
      elsif options.has_key?(n)
        options[n]
      else
        raise NoMethodError
      end
    end
    
  end


  class CitationContext < Context
    def initialize(options = nil, sort = nil, layout = nil)
      super
    end
  end

  
  class BibliographyContext < Context
    def initialize(options = nil, sort = nil, layout = nil)
      super
    end
  end
  
  
  class Sort
    attr_accessor :keys

    def initialize
      @keys = []
    end
    
    def add_key(key)
      @keys << key
    end

    alias << add_key
  end
  

  # ---------- Layout classes -----------
  
  class Layout < GroupingElement
    include Formatting, Delimiter

    def initialize(formatting = nil, delimiters = nil)
      super()
      @formatting = formatting
      @delimiters = delimiters
    end
  end

  

  # ---------- CSElement classes -----------
  
  # Abstract class
  class CSElement 
  end

  

  # ---------- Name classes -----------
  
  class ShortNames < CSElement
    include Formatting, Delimiter
    attr_accessor :variable

    def initialize(formatting = nil, delimiters = nil, variable = nil)
      @formatting = formatting
      @delimiters = delimiters
      @variable = variable
    end    
    
    def == other
      variable == other.variable if other.kind_of? ShortNames
    end
    
    alias value variable
  end
  
  class Names < ShortNames
    attr_accessor :name, :labels, :substitute

    def initialize(formatting = nil, delimiters = nil, variable = nil)
      super(formatting, delimiters, variable)
      @names = []
      @labels = []
    end    
    
    def add_label(name_label)
      @labels << name_label
    end
    
    def each_label(&block)
      @name_labels.each(block)
    end
  end
  
  class Name
    include Formatting, Delimiter
    attr_accessor :form, :and, :delimiter_precedes_last, :name_as_sort_order, :sort_separator, :initialize_with

    def initialize(formatting = nil, delimiters = nil, 
      form = nil, _and = nil, delimiter_precedes_last = nil, 
      name_as_sort_order = nil, sort_separator = nil, initialize_with = nil)
      @formatting = formatting
      @delimiters = delimiters
      @form = form
      @and = _and
      @delimiter_precedes_last = delimiter_precedes_last
      @name_as_sort_order = name_as_sort_order
      @sort_separator = sort_separator
      @initialize_with = initialize_with
    end    
  end
  
  class NameLabel < CSElement
    include Formatting
    attr_accessor :include_period, :form

    def initialize(formatting = nil, include_period = nil, form = nil)
      @formatting = formatting
      @include_period = include_period
      @form = form
    end    
  end
  
  class Substitute < GroupingElement
    attr_accessor :names

    def initialize
      super
      @names = []
    end
    
    # Overrides add_element to handle ShortNames
    def add_element(element)
      @elements << element
      case 
      when element.kind_of?(Names)
        @names << element
      when element.kind_of?(Date)
        @dates << element
      when element.kind_of?(Label)
        @labels << element
      when element.kind_of?(Text)
        @texts << element
      when element.kind_of?(Group)
        @groups << element
      when element.kind_of?(ConditionGroup)
        @conditionals << element
      when element.kind_of?(ShortNames)
        @names << element
      end
    end

    alias << add_element
  end

  

  # ---------- Date classes -----------
  
  class Date < CSElement
    include Formatting, Delimiter
    attr_accessor :variable, :dateparts

    def initialize(formatting = nil, delimiters = nil, variable = nil)
      @formatting = formatting
      @delimiters = delimiters
      @variable = variable
      @dateparts = []
    end    
    
    def add_datepart(datepart)
      @dateparts << datepart
    end

    alias << add_datepart    
    alias value variable
  end  
  
  class DatePart
    include Formatting
    attr_accessor :name, :form, :include_period
    
    def initialize(formatting = nil, name = nil, form = nil, include_period = nil)
      @formatting = formatting
      @name = name
      @form = form
      @include_period = include_period
    end    
  end

  

  # ---------- Label class -----------
  
  class Label < CSElement
    include Formatting
    attr_accessor :include_period, :form, :variable

    def initialize(formatting = nil, include_period = nil, form = nil, variable = nil)
      @formatting = formatting
      @include_period = include_period
      @form = form
      @variable = variable
    end    
  end

  

  # ---------- Text classes -----------
  
  
  class Text < CSElement
    include Formatting

    def initialize(formatting = nil)
      @formatting = formatting
    end    
  end
  
  class VariableText < Text
    include Delimiter
    attr_accessor :variable

    def initialize(formatting = nil, delimiters = nil, variable = nil)
      #@formatting = formatting
      super(formatting)
      @delimiters = delimiters
      @variable = variable
    end    
    
    alias value variable
  end
  
  class MacroText < Text
    attr_accessor :macro

    def initialize(formatting = nil, macro = nil)
      super(formatting)
      @macro = macro
    end    
    
    alias value macro
  end
  
  class TermText < Text
    attr_accessor :term

    def initialize(formatting = nil, term = nil)
      super(formatting)
      @term = term
    end    
    
    alias value term
  end
  
  class ValueText < Text
    attr_accessor :value

    def initialize(formatting = nil, value = nil)
      super(formatting)
      @value = value
    end    
  end

  

  # ---------- Group classes -----------
  
  class Group < GroupingElement
    include Formatting, Delimiter
    attr_reader :class_name

    def initialize(formatting = nil, delimiters = nil, class_name = nil)
      super()
      @formatting = formatting
      @delimiters = delimiters
      @class_name = class_name
    end
  end

  

  # ---------- Condition classes -----------
  
  class ConditionGroup
    include Enumerable
    attr_accessor :conditions

    def initialize
      @conditions = []
    end
    
    def add_condition(condition)
      @conditions << condition
    end
    
    def each(&block)
      @conditions.each(&block) if @conditions
    end
    
    alias << add_condition
  end
  
  class Condition < GroupingElement
    attr_accessor :type, :variable, :position, :disambiguate, :locator, :match
  end
end
