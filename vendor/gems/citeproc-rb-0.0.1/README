citeproc-rb README
==================

NB: citeproc-rb is currently incomplete and error-prone. 
Please check http://xbiblio.sourceforge.net/ regularly for updates.


Overview
--------

citeproc-rb is a Ruby port of Citeproc, a process for converting citations
into a variety of formats using a macro language called Citation Style Language
(CSL). For more details on Citeproc and CSL, please check 
http://xbiblio.sourceforge.net/.

citeproc-rb itself is currently designed to citations in two formats: an internal 
CSL model and Bibliontology (http://bibliontology). Bibliontology itself is
designed to support a range of additional formats, such as BibTeX, greatly
extending the range of formats supported.

The basic classes of Citeproc-rb is as follows:

Citeproc        - the main process for Citeproc; controls the processing
                  pipeline
InputFilter     - converts input sources and provides a standard interface for
                  retrieving citation data
Csl             - the CSL object model
CslParser       - parses CSL rules into an object model
CslProcessor    - processes citations according to the CSL rules
BaseFormatter   - formats citations in plain text
XhtmlFormatter  - formats citations in XHTML

Together these classes form a processing pipeline: the Citeproc controls 
filtering citations input; the parsing of CSL rules; and 
formatting the citations according to the rules.

The InputFilter class provides some basic services but is designed to be 
sub-classed for particular input formats. 


Requirements
------------

  * ruby 1.8
    <http://www.ruby-lang.org/>

Optional:

  * Rubygems
    <http://www.rubygems.org/>

  * ActiveSupport
    <http://rubyforge.org/projects/activesupport/>

  * YAML
    <http://yaml4r.sourceforge.com/>

  * JSON
    <http://json.rubyforge.com/>

  * Redland Ruby bindings (for Bibliontology support)
    <http://librdf.org/>



Usage
-----

To use the internal CSL model with JSON:

  ruby examples/citeproc_driver.rb --input test/fixtures/csl_test_data.json --content-type json --csl data/styles/ama.csl

With YAML:

  ruby examples/citeproc_driver.rb --input test/fixtures/csl_test_data.yaml --content-type yaml --csl data/styles/ama.csl

To use Bibliontology data, again with YAML (but note the YAML includes class specifications):

  ruby examples/citeproc_driver.rb --input-filter bibo --input test/fixtures/bibo_test_data.yaml --content-type yaml --csl data/styles/ama.csl

With RDF (presumes Redland with Ruby bindings is installed):

  ruby examples/citeproc_driver.rb --input-filter bibo --input test/fixtures/bibo_test_data.xml --content-type rdf --csl data/styles/ama.csl



License
-------

You can redistribute it and/or modify it under the same term as Ruby.


Liam Magee <liam.magee@gmail.com>