#!/usr/bin/env ruby

#$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib") if __FILE__ == $0

#require 'test/test_sample_bibo'

puts "Checking for test cases:"
Dir['test/test_*.rb'].each do |testcase|
  unless testcase == __FILE__
    puts "\t#{testcase}"
    require testcase 
  end
end
puts " "