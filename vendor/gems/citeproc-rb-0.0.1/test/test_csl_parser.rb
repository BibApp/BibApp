#! /usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'citeproc'

class TestCslParser < Test::Unit::TestCase
  def stub_csl_files 
    [
      "test/fixtures/styles/test_csl_parse.csl"
    ]
  end
  
  def stub_locale_files 
    [
      "test/fixtures/locales/test_locale_en.xml"
    ]
  end


  def setup
    @csl_style = Citeproc::CslParser.new(stub_csl_files[0]).style
    @terms = Citeproc::CslParser.new(stub_locale_files[0]).style
  end

  # Tests the core Style object
  def test_style
    assert_not_nil(@csl_style)
    assert_equal(@csl_style.lang, "en")
  end
  
  # Tests the Info object
  def test_info
    assert_not_nil(@csl_style.info)
    assert_not_nil(@csl_style.info.id)
    assert_not_nil(@csl_style.info.authors)

    assert_equal "American Psychological Association", @csl_style.info.title.text
    assert_equal "http://www.zotero.org/styles/apa", @csl_style.info.id
    assert_equal "http://www.zotero.org/styles/apa", @csl_style.info.links[0].to_s
    
    assert_equal "Simon Kornblith", @csl_style.info.authors[0].name
    assert_equal "simon@simonster.com", @csl_style.info.authors[0].email
    assert_equal "psychology", @csl_style.info.categories[0].term
    assert_equal "generic-base", @csl_style.info.categories[1].term
    assert_equal "author-date",   @csl_style.info.categories[2].term

    assert_kind_of Time, @csl_style.info.updated 
    # Need to convert date formats prior to comparison
    #assert_equal @csl_style.info.updated.to_s, "2007-09-06T06:36:07+00:00"
  end

  # Tests the Macros object
  def test_macros
    assert_not_nil(@csl_style.macros)
    assert_equal(13, @csl_style.macros.size)
    
    # First macro
    assert_equal("container-contributors", @csl_style.macros[0].name)
#    assert_equal("(", @csl_style.macros[0].names[0].prefix)
#    assert_equal(")", @csl_style.macros[0].names[0].suffix)
#    assert_equal(", ", @csl_style.macros[0].names[0].delimiter)
#    assert_equal("symbol", @csl_style.macros[0].names[0].name.and)
#    assert_equal(". ", @csl_style.macros[0].names[0].name.initialize_with)
#    assert_equal(", ", @csl_style.macros[0].names[0].name.delimiter)
#    assert_equal("short", @csl_style.macros[0].names[0].labels[0].form)
#    assert_equal(", ", @csl_style.macros[0].names[0].labels[0].prefix)
#    assert_equal("capitalize", @csl_style.macros[0].names[0].labels[0].text_transform)
#    assert_equal(".", @csl_style.macros[0].names[0].labels[0].suffix)
#    
#    # Second macro
#    assert_equal("author", @csl_style.macros[1].name)
#    assert_equal("author", @csl_style.macros[1].names[0].variable)
#    assert_equal("all", @csl_style.macros[1].names[0].name.name_as_sort_order)
#    assert_equal("symbol", @csl_style.macros[1].names[0].name.and)
#    assert_equal(", ", @csl_style.macros[1].names[0].name.sort_separator)
#    assert_equal(". ", @csl_style.macros[1].names[0].name.initialize_with)
#    assert_equal(", ", @csl_style.macros[1].names[0].name.delimiter)
#    assert_equal("always", @csl_style.macros[1].names[0].name.delimiter_precedes_last)
#    
#    assert_equal("short", @csl_style.macros[1].names[0].labels[0].form)
#    assert_equal(" (", @csl_style.macros[1].names[0].labels[0].prefix)
#    assert_equal(".)", @csl_style.macros[1].names[0].labels[0].suffix)
#    assert_equal("capitalize", @csl_style.macros[1].names[0].labels[0].text_transform)
#
#    assert_equal("editor", @csl_style.macros[1].names[0].substitute.names[0].variable)
#    assert_equal("translator", @csl_style.macros[1].names[0].substitute.names[1].variable)
#    assert_equal("title", @csl_style.macros[1].names[0].substitute.texts[0].macro)
    
  end
  
  # Tests the Citation object
  def test_citation
    assert_not_nil(@csl_style.citation)
    assert_not_nil(@csl_style.citation.options)
    assert_not_nil(@csl_style.citation.sort)
    assert_not_nil(@csl_style.citation.layout)

    # Test the options
    assert_equal "6", @csl_style.citation.option("et-al-min")
    assert_equal "6", @csl_style.citation.et_al_min
    assert_equal "1", @csl_style.citation.et_al_use_first
    assert_equal "3", @csl_style.citation.et_al_subsequent_min
    assert_equal "1", @csl_style.citation.et_al_subsequent_use_first
    assert_equal "true", @csl_style.citation.disambiguate_add_year_suffix
    assert_equal "true", @csl_style.citation.disambiguate_add_names
    assert_equal "true", @csl_style.citation.disambiguate_add_givenname
    assert_equal "year", @csl_style.citation.collapse

    # Test the sort keys
#    assert_equal "macro", @csl_style.citation.sort_options[0].type
#    assert_equal "author", @csl_style.citation.sort_options[0].value
#    assert_equal "variable", @csl_style.citation.sort_options[1].type
#    assert_equal "issued", @csl_style.citation.sort_options[1].value

    # Test the layout attributes
    assert_equal "(", @csl_style.citation.layout.prefix
    assert_equal ")", @csl_style.citation.layout.suffix
    assert_equal "; ", @csl_style.citation.layout.delimiter

    # Test the layout object graph
    assert_equal ", ", @csl_style.citation.layout.groups[0].delimiter
    assert_not_nil @csl_style.citation.layout.groups[0].texts[0]
    
    assert_kind_of Citeproc::MacroText, @csl_style.citation.layout.groups[0].texts[0]
    assert_equal "author-short", @csl_style.citation.layout.groups[0].texts[0].macro
    assert_equal "author-short", @csl_style.citation.layout.groups[0].texts[0].value
    
    # No longer here?
    # assert_kind_of Citeproc::Date, @csl_style.citation.layout.groups[0].dates[0]
    # assert_equal "issued", @csl_style.citation.layout.groups[0].dates[0].variable
    # assert_equal "issued", @csl_style.citation.layout.groups[0].dates[0].value
    # assert_equal "year", @csl_style.citation.layout.groups[0].dates[0].dateparts[0].name
    
    # assert_not_nil @csl_style.citation.layout.groups[0].groups[0].labels[0]
    # assert_equal "locator", @csl_style.citation.layout.groups[0].groups[0].labels[0].variable
    # assert_equal "true", @csl_style.citation.layout.groups[0].groups[0].labels[0].include_period
    # assert_equal "short", @csl_style.citation.layout.groups[0].groups[0].labels[0].form

    # assert_not_nil @csl_style.citation.layout.groups[0].groups[0].texts[0]
    # assert_kind_of Citeproc::VariableText, @csl_style.citation.layout.groups[0].groups[0].texts[0]
    # assert_equal "locator", @csl_style.citation.layout.groups[0].groups[0].texts[0].variable
    # assert_equal " ", @csl_style.citation.layout.groups[0].groups[0].texts[0].prefix
  end
  
  # Tests the Bibliography object
  def test_bibliography
    assert_not_nil(@csl_style.bibliography)
    assert_not_nil(@csl_style.bibliography.options)
    assert_not_nil(@csl_style.bibliography.sort)
    assert_not_nil(@csl_style.bibliography.layout)
    assert_not_nil(@csl_style.bibliography.layout.conditionals)

    # Test one of the options
    assert_equal "true", @csl_style.bibliography.option("hanging-indent")
    assert_equal "true", @csl_style.bibliography.hanging_indent
    assert_equal "6", @csl_style.bibliography.et_al_min
    assert_equal "6", @csl_style.bibliography.et_al_use_first

    # Test the sort keys
#    assert_equal "macro", @csl_style.bibliography.sort_options[0].type
#    assert_equal "author", @csl_style.bibliography.sort_options[0].value
#    assert_equal "variable", @csl_style.bibliography.sort_options[1].type
#    assert_equal "issued", @csl_style.bibliography.sort_options[1].value

    # Test the layout object graph
    assert_kind_of Citeproc::MacroText, @csl_style.bibliography.layout.texts[0]
    assert_equal "author", @csl_style.bibliography.layout.texts[0].value
    assert_equal ".", @csl_style.bibliography.layout.texts[0].suffix

    # Dates no longer here?
    # assert_kind_of Citeproc::Date, @csl_style.bibliography.layout.dates[0]
    # assert_equal "issued", @csl_style.bibliography.layout.dates[0].value
    # assert_equal " (", @csl_style.bibliography.layout.dates[0].prefix
    # assert_equal ").", @csl_style.bibliography.layout.dates[0].suffix
    # assert_equal "year", @csl_style.bibliography.layout.dates[0].dateparts[0].name
    
    # if
#    assert_equal "book", @csl_style.bibliography.layout.conditionals[0].conditions[0].type
#    assert_equal ".", @csl_style.bibliography.layout.conditionals[0].conditions[0].groups[0].suffix
#    assert_equal "title", @csl_style.bibliography.layout.conditionals[0].conditions[0].groups[0].texts[0].macro
#    assert_equal " ", @csl_style.bibliography.layout.conditionals[0].conditions[0].groups[0].texts[0].prefix
#    assert_equal "editor-translator", @csl_style.bibliography.layout.conditionals[0].conditions[0].groups[0].texts[1].macro
#    assert_equal " ", @csl_style.bibliography.layout.conditionals[0].conditions[0].groups[0].texts[1].prefix
#    assert_equal " ", @csl_style.bibliography.layout.conditionals[0].conditions[0].texts[0].prefix
#    assert_equal ".", @csl_style.bibliography.layout.conditionals[0].conditions[0].texts[0].suffix
#    assert_equal "publisher", @csl_style.bibliography.layout.conditionals[0].conditions[0].texts[0].macro
    
    # else-if
#    assert_equal "chapter", @csl_style.bibliography.layout.conditionals[0].conditions[1].type
#    assert_equal "title", @csl_style.bibliography.layout.conditionals[0].conditions[1].texts[0].macro
#    assert_equal " ", @csl_style.bibliography.layout.conditionals[0].conditions[1].texts[0].prefix
#    assert_equal "container", @csl_style.bibliography.layout.conditionals[0].conditions[1].groups[0].class_name
#    assert_equal "in", @csl_style.bibliography.layout.conditionals[0].conditions[1].groups[0].texts[0].term
#    assert_equal "capitalize", @csl_style.bibliography.layout.conditionals[0].conditions[1].groups[0].texts[0].text_transform
#    assert_nil @csl_style.bibliography.layout.conditionals[0].conditions[1].groups[0].groups[0].prefix
#    assert_equal ", ", @csl_style.bibliography.layout.conditionals[0].conditions[1].groups[0].groups[0].delimiter
#    assert_equal ".", @csl_style.bibliography.layout.conditionals[0].conditions[1].groups[0].groups[0].suffix
#    assert_equal "editor translator", @csl_style.bibliography.layout.conditionals[0].conditions[1].groups[0].groups[0].names[0].variable
#    assert_equal " ", @csl_style.bibliography.layout.conditionals[0].conditions[1].groups[0].groups[0].names[0].prefix
#    assert_equal ", ", @csl_style.bibliography.layout.conditionals[0].conditions[1].groups[0].groups[0].names[0].delimiter
#    assert_equal "symbol", @csl_style.bibliography.layout.conditionals[0].conditions[1].groups[0].groups[0].names[0].name.and
#    assert_equal ", ", @csl_style.bibliography.layout.conditionals[0].conditions[1].groups[0].groups[0].names[0].name.sort_separator
#    assert_equal ". ", @csl_style.bibliography.layout.conditionals[0].conditions[1].groups[0].groups[0].names[0].name.initialize_with
#    assert_equal " ", @csl_style.bibliography.layout.conditionals[0].conditions[1].groups[0].groups[0].groups[0].delimiter

    # else
#    assert_equal ". ", @csl_style.bibliography.layout.conditionals[0].conditions[1].groups[0].prefix
#    assert_equal ".", @csl_style.bibliography.layout.conditionals[0].conditions[2].groups[0].suffix
#    assert_equal "container", @csl_style.bibliography.layout.conditionals[0].conditions[2].groups[1].class_name
#    assert_equal " ", @csl_style.bibliography.layout.conditionals[0].conditions[2].groups[1].prefix
#    assert_equal ".", @csl_style.bibliography.layout.conditionals[0].conditions[2].groups[1].suffix
    
    # Check element order
    assert_kind_of Citeproc::MacroText, @csl_style.bibliography.layout.elements[0]
    assert_kind_of Citeproc::MacroText, @csl_style.bibliography.layout.elements[1]
    assert_kind_of Citeproc::MacroText, @csl_style.bibliography.layout.elements[2]
    assert_kind_of Citeproc::MacroText, @csl_style.bibliography.layout.elements[3]
    
  end
  
end
