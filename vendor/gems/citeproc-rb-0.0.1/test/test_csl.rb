#! /usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'citeproc'

class TestCsl < Test::Unit::TestCase
  FIXTURES = { :csl_json => 'test/fixtures/csl_test_data.json' } 
  
  def get_csl(path)
    styles = {}
    Dir[path + '/*.csl'].each do |f|
      styles[f.match(/test_(.*)\.csl/)[1].to_sym] = Citeproc::CslParser.new(f).style
    end
    styles
  end


  def setup
    @styles = get_csl('test/fixtures/styles')
    @locales = get_csl('test/fixtures/locales')
    @input_filter = CSL::CslInputFilter.new
    @input_filter.parse(FIXTURES[:csl_json], { :content_type => 'json' })
    @processor = Citeproc::CslProcessor.new
    @formatter = Citeproc::BaseFormatter.new
  end
  
  
  def test_sort
    sort_style = @styles[:sort]
    @processor.init_process(@input_filter, sort_style, @locales[:locale_en])
    citations = @input_filter.citations.values
    keyset = @processor.generate_sort_keys(sort_style.bibliography)
    sorted_citations = @input_filter.sorted_citations(keyset)

    #puts citations.collect {|c| c.authors.collect {|a| a.name} if c.authors }
    #puts sorted_citations.collect {|c| c.authors.collect {|a| a.name} if c.authors }
    assert(citations[4] == sorted_citations[1])
    assert(citations[1] == sorted_citations[2])
  end
  
  def test_name_sort
    sort_style = @styles[:sort]
    @processor.init_process(@input_filter, sort_style, @locales[:locale_en])
    citations = @input_filter.citations.values

    second_citation = citations[2]
    unsorted = second_citation.contributors("author")
    sorted_by_first = second_citation.contributors("author", "first")
    sorted_by_all = second_citation.contributors("author", "all")

    assert(unsorted[0] == sorted_by_first[0])
    assert(unsorted[0] == sorted_by_all[1])
    assert(unsorted[1] == sorted_by_first[1])
    assert(unsorted[1] == sorted_by_all[0])
    assert(unsorted[2] == sorted_by_first[2])
    assert(unsorted[2] == sorted_by_all[2])
    assert(unsorted[3] == sorted_by_first[3])
    assert(unsorted[3] == sorted_by_all[3])
  end
  
  
  def test_names
    # Tests with AMA-style names
    names_style = @styles[:names]
    nodes = @processor.process_bibliography(@input_filter, names_style, @locales[:locale_en])
    results = @formatter.format(nodes)
    puts 
    puts "Testing name values:"
    puts results
    lines = results.split("\n")
    assert(lines[0].strip.empty?)

    # Assert full stop
    assert(lines[1][lines[1].length - 1..lines[1].length - 1] == '.')
    assert(lines[2][lines[2].length - 1..lines[2].length - 1] == '.')
    assert(lines[3][lines[3].length - 1..lines[3].length - 1] == '.')
    assert(lines[4][lines[4].length - 1..lines[4].length - 1] == '.')
    
    # Assert spaces
    assert(lines[1].split.length == 2)
    assert(lines[2].split.length == 8)
    
    # Assert values
    assert(lines[1] == "Doniger W.")
    assert(lines[2] == "Gagnon JH, Laumann EO, Michael RT, Michaels S.")
    assert(lines[3] == "Smith JM.")
    assert(lines[4] == "Doe J, Smith J.")


    # Assert spaces
    #puts lines[1]
  end
  
  
  def test_group
    groups_style = @styles[:groups]
    nodes = @processor.process_bibliography(@input_filter, groups_style, @locales[:locale_en])
    
    # Get the first node
    first_node = nodes[0]
    
    # Get the first group node
    group_node = first_node.children[0]
    results = @formatter.format(group_node)
    assert(results.empty?)

    group_node = first_node.children[1]
    results = @formatter.format(group_node)
    assert_equal("The words 'Some Title' appear in the citation.", results)
  end
  
  def test_macro_expansion
    assert(true)
  end
  
  
  def test_labels
    assert(true)
  end
  
  
  def test_substitutions
    assert(true)
  end

  
  def test_grouping
    assert(true)
  end  

  
  def test_formatting
    assert(true)
  end  
end
