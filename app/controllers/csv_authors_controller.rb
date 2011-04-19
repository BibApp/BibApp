# useful for command line pushing of csv delimited people
# may need to change parameter names being passed to this controller
# for security reasons it's probably a good idea to change the controller name and secure access

class CSVAuthorController < ApplicationController
  
  protect_from_forgery :except => [:csv]
  
  # loading persons via csv 
  def csv

    permit "admin"

    if request.post?
      
      #render :inline => params.inspect and return
      
        begin
          msg = ''
          
          # need to match request param here
          data = params[:arg]
          filename = params[:arg].original_filename
          
          str = ''
          if data.respond_to?(:read)
            str = data.read
          elsif File.readable?(data)
            str = File.read(data)
          else
            msg = 'The File you submitted could not be read.'
          end

          if msg.empty?
            unless str.is_utf8?
              encoding = CMess::GuessEncoding::Automatic.guess(str)
              unless encoding.nil? or encoding.empty? or encoding==CMess::GuessEncoding::Encoding::UNKNOWN
                str =Iconv.iconv('UTF-8', encoding, str).to_s
              else
                logger.error("The character encoding could not be determined or could not be converted to UTF-8.\n")
                msg = 'The file could not be converted to UTF8.'
              end
            end
            
            # ***this is command line http generated request
            msg = "current user is nil, aborting" if current_user.nil? 
            
            if msg.empty?
              Delayed::Job.enqueue CsvPeopleUpload.new(str, current_user.id, filename)
              msg = "#{current_user.email}, Your file was accepted for processing. An email will notify you when the job is completed."
            end
          end
          
        rescue Exception => e
          msg = "An error was generated processing your request. #{e.to_s}"
        end
        
         render :inline => msg 
    
    else
      
      # render a get to action template
      # shouldn't return anything
      render :inline => ''
    end
    
  end
  
  
end
