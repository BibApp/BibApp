$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__) + '/../../activesupport/lib/active_support')
$:.unshift(File.dirname(__FILE__) + '/fixtures/helpers')

require 'yaml'
require 'stringio'
require 'test/unit'
require 'action_controller'
require 'action_controller/cgi_ext'
require 'action_controller/test_process'

begin
  require 'ruby-debug'
rescue LoadError
  # Debugging disabled. `gem install ruby-debug` to enable.
end

# Show backtraces for deprecated behavior for quicker cleanup.
ActiveSupport::Deprecation.debug = true

ActionController::Base.logger = nil
ActionController::Base.ignore_missing_templates = false
ActionController::Routing::Routes.reload rescue nil


# Wrap tests that use Mocha and skip if unavailable.
def uses_mocha(test_name)
  unless Object.const_defined?(:Mocha)
    require 'mocha'
    require 'stubba'
  end
  yield
rescue LoadError => load_error
  raise unless load_error.message =~ /mocha/i
  $stderr.puts "Skipping #{test_name} tests. `gem install mocha` and try again."
end
