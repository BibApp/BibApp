#!/usr/bin/env ruby

require 'test/unit'
require File.dirname(__FILE__) + '/../../lib/sass'
require 'sass/engine'

class SassEngineTest < Test::Unit::TestCase
  EXCEPTION_MAP = {
    "!a = 1 + " => 'Constant arithmetic error: "1 +"',
    "!a = 1 + 2 +" => 'Constant arithmetic error: "1 + 2 +"',
    "!a = \"b" => 'Unterminated string: "\\"b"',
    "!a = #aaa - a" => 'Undefined operation: "#aaaaaa minus a"',
    "!a = #aaa / a" => 'Undefined operation: "#aaaaaa div a"',
    "!a = #aaa * a" => 'Undefined operation: "#aaaaaa times a"',
    "!a = #aaa % a" => 'Undefined operation: "#aaaaaa mod a"',
    "!a = 1 - a" => 'Undefined operation: "1 minus a"',
    "!a = 1 * a" => 'Undefined operation: "1 times a"',
    "!a = 1 / a" => 'Undefined operation: "1 div a"',
    "!a = 1 % a" => 'Undefined operation: "1 mod a"',
    ":" => 'Invalid attribute: ":"',
    ": a" => 'Invalid attribute: ": a"',
    ":= a" => 'Invalid attribute: ":= a"',
    "a\n  :b" => 'Invalid attribute: ":b "',
    "a\n  :b: c" => 'Invalid attribute: ":b: c"',
    "a\n  :b:c d" => 'Invalid attribute: ":b:c d"',
    "a\n  :b=c d" => 'Invalid attribute: ":b=c d"',
    "a\n  :b c;" => 'Invalid attribute: ":b c;" (This isn\'t CSS!)',
    "a\n  b : c" => 'Invalid attribute: "b : c"',
    "a\n  b=c: d" => 'Invalid attribute: "b=c: d"',
    ":a" => 'Attributes aren\'t allowed at the root of a document.',
    "!" => 'Invalid constant: "!"',
    "!a" => 'Invalid constant: "!a"',
    "! a" => 'Invalid constant: "! a"',
    "!a b" => 'Invalid constant: "!a b"',
    "a\n\t:b c" => "Illegal Indentation: Only two space characters are allowed as tabulation.",
    "a\n :b c" => "Illegal Indentation: Only two space characters are allowed as tabulation.",
    "a\n    :b c" => "Illegal Indentation: Only two space characters are allowed as tabulation.",
    "a\n  :b c\n  !d = 3" => "Constants may only be declared at the root of a document.",
    "!a = 1b + 2c" => "Incompatible units: b and c",
    "& a\n  :b c" => "Base-level rules cannot contain the parent-selector-referencing character '&'",
    "a\n  :b\n    c" => "Illegal nesting: Only attributes may be nested beneath attributes.",
    "!a = b\n  :c d\n" => "Illegal nesting: Nothing may be nested beneath constants.",
    "@import foo.sass" => "File to import not found or unreadable: foo.sass",
    "@import templates/basic\n  foo" => "Illegal nesting: Nothing may be nested beneath import directives.",
    "foo\n  @import templates/basic" => "Import directives may only be used at the root of a document.",
    "@foo    bar boom" => "Unknown compiler directive: \"@foo bar boom\"",
  }
  
  def test_basic_render
    renders_correctly "basic", { :style => :compact }
  end

  def test_alternate_styles
    renders_correctly "expanded", { :style => :expanded }
    renders_correctly "compact", { :style => :compact }
    renders_correctly "nested", { :style => :nested }
  end
  
  def test_exceptions
    EXCEPTION_MAP.each do |key, value|
      begin
        Sass::Engine.new(key).render
      rescue Sass::SyntaxError => err
        assert_equal(value, err.message)
        assert(err.sass_line, "Line: #{key}")
        assert_match(/\(sass\):[0-9]+/, err.backtrace[0], "Line: #{key}")
      else
        assert(false, "Exception not raised for\n#{key}")
      end
    end
  end

  def test_exception_line
    to_render = "rule\n  :attr val\n// comment!\n\n  :broken\n"
    begin
      Sass::Engine.new(to_render).render
    rescue Sass::SyntaxError => err
      assert_equal(5, err.sass_line)
    else
      assert(false, "Exception not raised for '#{to_render}'!")
    end
  end

  def test_imported_exception
    [1, 2].each do |i|
      i = nil if i == 1
      begin
        Sass::Engine.new("@import bork#{i}", :load_paths => [File.dirname(__FILE__) + '/templates/']).render
      rescue Sass::SyntaxError => err
        assert_equal(2, err.sass_line)
        assert_match(/bork#{i}\.sass$/, err.sass_filename)
      else
        assert(false, "Exception not raised for imported template: bork#{i}")
      end
    end
  end

  def test_empty_first_line
    assert_equal("#a {\n  b: c; }\n", Sass::Engine.new("#a\n\n  b: c").render)
  end
    
  private

  def renders_correctly(name, options={})
    sass_file  = load_file(name, "sass")
    css_file   = load_file(name, "css")
    css_result = Sass::Engine.new(sass_file, options).render
    assert_equal css_file, css_result
  end

  def load_file(name, type = "sass")
    @result = ''
    File.new(File.dirname(__FILE__) + "/#{type == 'sass' ? 'templates' : 'results'}/#{name}.#{type}").each_line { |l| @result += l }
    @result
  end
end
