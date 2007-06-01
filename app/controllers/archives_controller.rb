class ArchivesController < ApplicationController
  include FileUtils
  
  # Handle the importation of a great huge directory full of files.
  # The contained files should be named /(\d+)\.\w+/, where the digits
  # correspond to citation.id of a record with archive_status_id = 4.
  # We then store all the files in an export directory and flag those citations
  # as ready for export (archive_status_id = 5)
  
  def create
    
    archive_dir = Dir.new(ARCHIVE_UPLOAD_DIR)
    if request.post?
      FileUtils.mkdir(ARCHIVE_OUTPUT_DIR) unless File.exist?(ARCHIVE_OUTPUT_DIR)
      output_dir = "#{ARCHIVE_OUTPUT_DIR}/#{Time.now.to_i.to_s}"
      FileUtils.mkdir(output_dir) unless File.exist?(output_dir)
      files = archive_dir.reject { |f| f =~ /^\./ }
      # will look like item_001. Perhaps uneccesary - EL 1/18/2006
      #cur_item = "item_#{1.to_s.rjust(files.size.to_s.length+1, "0")}"
      files.each do |f|
        # We'll skip any files where we can't find a citation
        # Or any where it's already been archived
        cite = Citation.find_by_id(f.to_i.from_verhoeff)
        next if cite.nil? or cite.archive_status_id != 4 or cite.publication.nil? or cite.publication.publisher.dspace_xml.nil?
        cur_dir = "#{output_dir}/#{cite.id}"
        # this 'unless' should never happen. But it won't be an error anyhow
        FileUtils.mkdir(cur_dir) unless File.exist?(cur_dir)
        xmlfile = File.open("#{cur_dir}/dublin_core.xml", 'w')
        xmlfile.write(to_dspace_xml(cite))
        xmlfile.close
        contents = File.open("#{cur_dir}/contents", 'w')
        contents.write("file_1.pdf")
        contents.close
        FileUtils.mv("#{ARCHIVE_UPLOAD_DIR}/#{f}", "#{cur_dir}/file_1.pdf")
        # item_99.succ == iten_00. Funny!
        cite.archive_status_id = 5
        cite.save
        #cur_item.succ!
      end
    end
    # A list of ready-to-archive citations (archive_status_id = 4, a matching file)
    @ready = Array.new
    # A list of filenames where there's no matching citation
    @nocite = Array.new
    # A list of citations (archive_status_id = 4) where no filename corresponds to our ID
    @nofile = Array.new
    
    # Pare off '.' and '..'
    
    files = archive_dir.reject { |f| f =~ /^\./ }
    # And get a list of corresponding citation IDs

    file_hash = Hash.new
    files.each do |f|
      file_hash[f] = f.to_i.from_verhoeff
    end

    cites = Citation.find_all_by_archive_status_id(4, :include => :publication)
    
    @ready = cites.find_all { |c|
      file_hash.has_value?(c.id)
    }
    logger.debug("Here is ready! #{@ready.size}")
    
    @ready.reject! {|c| !c.publication }
    logger.debug("And now...! #{@ready.size}")
    @ready.reject! {|c| !c.publication.publisher.dspace_xml }
    logger.debug("Now ready! #{@ready.size}")
    @nocite = file_hash.reject { |file, verhoeff| 
      cites.detect { |c| c.id == verhoeff } 
    }.keys
    @nofile = cites.reject { |c|
      file_hash.has_value?(c.id)
    }
  end
  
  private

  def to_dspace_xml(citation)
    builder = Builder::XmlMarkup.new(:indent => 2)
    xml = builder.dublin_core { |dc|
      dc.dcvalue(citation.title_primary, :element => "title", :qualifier => "none") if citation.title_primary and !citation.title_primary.empty?
      dc.dcvalue(citation.pub_year, :element => "date", :qualifier => "issued")
      dc.dcvalue(citation.publisher, :element => "publisher", :qualifier => "none") if citation.publisher and !citation.publisher.empty?
      if citation.publication.publisher.sherpa_id == 7
        dc.dcvalue(aip_notice(citation), :element => "rights", :qualifier => "none")
        dc.dcvalue(aip_link(citation), :element => "identifier", :qualifier => "citation")
      else
        dc.dcvalue(copyright_statement(citation), :element => "rights", :qualifier => "none")
        dc << citation.publication.publisher.dspace_xml
        dc.dcvalue(format_citation_apa_to_s(citation), :element => "identifier", :qualifier => "citation")
      end
      dc.dcvalue("This material is presented to ensure timely dissemination of scholarly and technical work. Copyright and all rights therein are retained by authors or by other copyright holders. All persons copying this information are expected to adhere to the terms and constraints invoked by each author's copyright. In most cases, these works may not be reposted without the explicit permission of the copyright holder.", :element => "description", :qualifier => "none")
      dc.dcvalue(citation.links, :element => "identifier", :qualifier => "doi") if citation.links and !citation.links.empty?
      dc.dcvalue(citation.publication.publisher.url, :element => "relation", :qualifier => "ispartof") if citation.publication.publisher.url and !citation.publication.publisher.url.empty?
      dc.dcvalue(citation.publication.url, :element => "relation", :qualifier => "ispartof") if citation.publication.url and !citation.publication.url.empty?
      dc.dcvalue("application/pdf", :element => "format", :qualifier => "mimetype")
      citation.author_array.each do |a|
        dc.dcvalue(a, :element => "contributor", :qualifier => "author")
      end
    }
    xml
  end
  
  def copyright_statement(citation)
    copyright_statement = "Copyright #{citation.pub_year} #{citation.publication.publisher.name}"
  end
  
  # AIP required notice
  def aip_notice(citation)
    aip_notice = "Copyright #{citation.pub_year} American Institute of Physics. This article may be downloaded for personal use only. Any other use requires prior permission of the author and the American Institute of Physics."
  end
  
  # AIP required link
  def aip_link(citation)
    if citation.publication.publication_code
      aip_link = "The following article appeared in #{format_citation_apa_to_s(citation)} and may be found at http://link.aip.org/link/?#{citation.publication.publication_code}/#{citation.volume}/#{citation.start_page}"
    else
      aip_link = "The following article appeared in #{format_citation_apa_to_s(citation)} and may be found at #{citation.publication.url}"
    end
  end
  
  def format_citation_apa_to_s(citation)
    apa = nil
    if citation.reftype_id == 5
      apa = "#{author_format(citation)} (#{citation.pub_year}). #{citation.title_primary}. In #{citation.title_secondary}, #{citation.volume}"
      apa +=  " (#{citation.issue})" if citation.issue && !citation.issue.empty?
      apa += ", #{citation.start_page}-#{citation.end_page}."
    elsif citation.reftype_id == 1
      apa =  author_format(citation) + ' '
      apa += '(' + citation.pub_year.to_s + '). ' if citation.pub_year
      apa += citation.title_primary.titleize + '. ' if citation.title_primary && !citation.title_primary.empty?
      apa += citation.periodical_full.titleize + ', ' if citation.periodical_full && !citation.periodical_full.empty?
      apa += citation.volume if citation.volume
      apa += '(' + citation.issue + ')' if citation.issue
      apa += ', ' + citation.start_page + '-' if citation.start_page
      apa += citation.end_page + '.' if citation.end_page
    end
    apa
  end

  # TODO: Rename to format_authors
  def author_format(citation)
     # determine author_string size
     # if size > 6
     citation.authors ||= ""
     author_array = citation.authors.split(/\|/)
     if author_array.size > 6
       append = ', et al.'
     else
       append = ""
     end
   
     author_string = author_array.slice(0...6).join(", ")       
     author_string = author_string.gsub(/(\w+,)(\w+)/, '\1 \2')

     if author_array.size > 6
       author_string = author_string.gsub(/, ([\w\s]+)(, [\w\. ]+)\z/, ', \1\2')
     else
       author_string = author_string.gsub(/, ([\w\s]+)(, [\w\. ]+)\z/, ', & \1\2')
     end

     # truncates hyphenated first names to initials
     while author_string =~ /(\w+)-(\w+)/
       first_part = $1
       second_part = $2
       first_initial = first_part.slice(0,1)
       second_initial = second_part.slice(0,1)
       author_string = author_string.sub(/(\w+)-(\w+)/, "#{first_initial}.#{second_initial}.")
     end

     while author_string =~ /and (\w+, )(\w{2,}),?/
      name = $2
      initial = name.slice(0,1)
      author_string = author_string.sub($2, " #{initial}.,")
     end

     # truncates one-word first names to initials
     while author_string =~ /(\w+, )(\w{2,})[\.,]/
      name = $2
      initial = name.slice(0,1)
      author_string = author_string.sub($2, " #{initial}.,")
     end

     author_string = author_string.gsub(/,,/, ',')

     # corrects case of all-caps names
     while author_string =~ /([A-Z]{2,})/
       corrected_name = $1.capitalize!
       author_string = author_string.sub($1, "#{corrected_name}")
     end

     # deletes potential comma after last author name
     author_string = author_string.gsub(/,\z/, '')

     # cleans up goofy multiple-initial formatting
     author_string = author_string.gsub(/([A-Z]\.), ([A-Z]\.)/, '\1\2') 

     # [last name], [first name] [middle initial]." -> "[last name], [first initial]. [middle initial]."
     while author_string =~ /(\w{2,}), (\w{2,}) ([A-Z]\.)/ || author_string =~ /(\w{2,}), (\w{2,})\z/
      first_name = $2
      first_initial = first_name.slice(0,1)
      author_string = author_string.sub($2, "#{first_initial}.")
     end

     # changes names with format "[full first name], [full last name]" to APA format
     while author_string =~ (/(\w{2,}), (\w{2,})/)
       first_name = $1
       last_name = $2
       initial = first_name.slice(0,1)
       author_string = author_string.sub(/(\w{2,}), (\w{2,})/, "#{last_name}, #{initial}.")
     end

     # one last correction for names that are still in "[initials], [last name]" format
     while author_string =~ /([A-Z]\.[A-Z]\.?) (\w+)/
       initials = $1
       last_name = $2
       author_string = author_string.sub(/([A-Z]\.){1,2} (\w+)/, "#{last_name}, #{initials}")
     end

    author_string = author_string + append
    author_string = author_string
  end

end