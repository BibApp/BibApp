namespace :worldcat do

  desc 'Tests the OCLC WorldCat xID service APIs \n
        Should print a successful hash for each service: xISBN, xISSN, xOCLCNUM.'
        
  task :test do
    
    puts "\n\n ===== TESTING WORLDCAT XID APIs =====\n\n"
    
    puts "=== Testing XISBN - The Buddhist Third Class Junkmail Oracle==="
    puts "-- XISBN Request('1888363886')"
    xisbn = XISBNRequest.new('1888363886')
    puts "-- XISBN Request.valid? => #{xisbn.valid?}"
    puts "-- XISBN Request URL => #{xisbn.api_url}"
    xisbn = xisbn.get_response
    puts "-- XISBN Response: => #{xisbn.data.inspect}"
    puts "=====================\n\n"

    
    puts "=== Testing XISSN - A List Apart ==="
    puts "-- XISSN Request('1534-0295')"
    xissn = XISSNRequest.new('1534-0295')
    puts "-- XISSN Request.valid? => #{xissn.valid?}"
    puts "-- XISSN Request URL => #{xissn.api_url}"
    xissn = xissn.get_response
    puts "-- XISSN Response: => #{xissn.data.inspect}"
    puts "=====================\n\n"
    
    
    puts "=== Testing XOCLCNUM - John Updike's The Centaur ==="
    puts "-- XOCLCNUM Request('292080')"
    xoclcnum = XOCLCNUMRequest.new('292080', {:method => 'getMetadata'})
    puts "-- XOCLCNUM Request.valid? => #{xoclcnum.valid?}"
    puts "-- XOCLCNUM Request URL => #{xoclcnum.api_url}"
    xoclcnum = xoclcnum.get_response
    puts "-- XOCLCNUM Response: => #{xoclcnum.data.inspect}"
    puts "=====================\n\n"
    
  end
end