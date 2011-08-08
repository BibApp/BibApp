xml << (render(:partial => 'package',
               :locals => {:work => @work, :filenames_only => @filenames_only}))