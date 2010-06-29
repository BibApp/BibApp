# == About citeproc.rb
#
# All of Citeproc-rb's various part are loaded when you use <tt>require 'citeproc'</tt>.
#
# For a full list of features and instructions, see the README.

module Citeproc
  VERSION = '0.1'
end

begin
  require 'rdf/redland'
rescue LoadError
end


require 'citeproc/csl'
require 'citeproc/csl_parser'
require 'citeproc/csl_processor'
require 'citeproc/csl_reference'
require 'citeproc/input_filter'
require 'citeproc/filters/csl_citation/csl_citation'
require 'citeproc/filters/csl_citation/csl_citation_input_filter'
require 'citeproc/filters/bibo/bibo'
require 'citeproc/filters/bibo/bibo_input_filter'
require 'citeproc/filters/bibo/bibo_utils'
require 'citeproc/filters/bibapp/bibapp'
require 'citeproc/filters/bibapp/bibapp_input_filter'
require 'citeproc/formatters/base_formatter'
require 'citeproc/formatters/xhtml_formatter'
