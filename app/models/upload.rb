class Upload
  def self.save(person, upload)
    ext = get_ext(upload[:file].original_filename)
    outfilename = "#{RAILS_ROOT}/public/files/#{person.id}#{ext}"
    File.open(outfilename, "w") { |outfile|
      upload['file'].each do |line|
        outfile.write(line)
      end
    }
    outfilename
  end
  
  private
  def self.get_ext(filename)
    last_dot = filename.rindex(".")
    ext = filename[(last_dot+1)..(filename.length)]
    # make sure there's nothing funny going on
    return '' if ext =~ /\W/
    return ".#{ext}"
  end
end
