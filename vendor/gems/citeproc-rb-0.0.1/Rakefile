require "rake/rdoctask"
require "rake/testtask"
require "rake/gempackagetask"

require "rubygems"

dir     = File.dirname(__FILE__)
lib     = File.join(dir, "lib", "citeproc.rb")
version = File.read('VERSION').chomp

task :default => [:test]

Rake::TestTask.new do |test|
  test.libs       << "test"
  test.test_files =  [ "test/test_all.rb" ]
  test.verbose    =  true
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_files.include( "README", "VERSION", "lib/" )
  rdoc.main     = "README"
  rdoc.rdoc_dir = "doc/html"
  rdoc.title    = "Citeproc-rb Documentation"
end



spec = Gem::Specification.new do |spec|
  spec.name     = "citeproc-rb"
  spec.version  = version
  spec.platform = Gem::Platform::RUBY
  spec.summary  = "Citeproc-rb is a Ruby port of the ."
  spec.files    = Dir.glob("{data,examples,lib,test}/**/*.{rb,csl,xml,n3,rdf,json,yaml}").
                      delete_if { |item| item.include?(".svn") } +
                      ["Rakefile"]

  spec.test_suite_file  =  "test/test_all.rb"
  spec.has_rdoc         =  true
  spec.extra_rdoc_files =  %w{README TODO VERSION}
  spec.rdoc_options     << '--title' << 'Citeproc-rb Documentation' <<
                           '--main'  << 'README'

  spec.require_path      = 'lib'

  spec.author            = "Liam Magee"
  spec.email             = "liam.magee@gmail.com"
  spec.homepage          = "http://xbiblio.sourceforge.org"
  spec.description       = <<END_DESC
Citeproc-rb is a Ruby port of Citeproc, a process for converting citations
into a variety of formats using a macro language called Citation Style Language
(CSL). For more details on Citeproc and CSL, please check 
http://xbiblio.sourceforge.net/.
END_DESC
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

desc "Show library's code statistics"
task :stats do
  require 'code_statistics'
  CodeStatistics.new( ["Citeproc-rb", "lib"], 
                      ["Functionals", "examples"], 
                      ["Units", "test"] ).to_s
end

desc "Add new files to Subversion"
task :add_to_svn do
  sh %Q{svn status | ruby -nae 'system "svn add \#{$F[1]}" if $F[0] == "?"' }
end

