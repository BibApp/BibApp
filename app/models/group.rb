class Group < ActiveRecord::Base
  class Record < ActiveRecord::Base 
    set_table_name :groups
  end
  
  validates_presence_of :name
  validates_uniqueness_of :name

  has_many :memberships
  has_many :people,
    :through => :memberships
  
  class << self
    
    def find_with_member_counts(*args)
      options = extract_options_from_args!(args)
      options[:select] = "groups.*, count(memberships.id) as member_count"
      options[:joins] = "JOIN memberships on groups.id = memberships.group_id"
      options[:order] = "groups.name ASC"
      options[:group] = "groups.id, groups.name, groups.suppress, groups.created_at"
      find(args.first, options)
    end
    
  end
  
  def to_param
    param_name = name.gsub(" ", "_")
    "#{id}-#{param_name}"
  end
  
  def tags
    tags = Tag.find_by_sql(
      ["SELECT tags.id, tags.name, count(*) as count
        FROM tags
          JOIN taggings ON tags.id = taggings.tag_id
          JOIN citations ON taggings.taggable_id = citations.id
          JOIN authorships ON citations.id = authorships.citation_id
          JOIN people ON authorships.person_id = people.id
          JOIN memberships ON people.id = memberships.person_id
        WHERE memberships.group_id = ?
        GROUP BY tags.id, tags.name
        ORDER BY count DESC
        LIMIT 25", id]
    )
  end

  # TODO: Refactor ALL OF THIS SHIT to make it generalize to People, Departments, Colleges, or the
  # system-at-large.
  # Really, this should see Tags changed into more Keyword and Keywording models,
  # and the Keywording model would handle this stuff.
  # Keywords would specifically be applied from database controlled vocabs, possibly
  # with stoplists and synonym rings and such... and be specifically knowlegable about
  # Citations and the like.

  # For now, department-only support is pretty bad-ass.

  def tags_by_year(limit = 25, bin_count = 5)
    tags_for_years(years_with_papers, limit, bin_count).reject { |ydata| ydata.tags.size < 1 }
  end

  def tags_for_years(year_range, limit = 25, bin_count = 5)
    # Ensure we have an array; we'll need this to get the list of years
    if year_range.is_a?(Enumerable) 
      year_arr = year_range.to_a
    else
      year_arr = [year_range]
    end

    year_tags = Array.new

    year_arr.each do |y|
      ydata = KeywordsHelper::YearTag.new
      ydata.year = y
      ydata.tags = Array.new

      tags = Tag.find_by_sql(
        ["SELECT tags.id, tags.name, count(citations.id) as count
          FROM citations
            JOIN authorships ON citations.id = authorships.citation_id
            JOIN people ON authorships.person_id = people.id
            JOIN memberships ON people.id = memberships.person_id
            JOIN taggings ON taggings.taggable_id = citations.id
            JOIN tags ON tags.id = taggings.tag_id
          WHERE memberships.group_id = ?
          AND citations.pub_year = ?
          GROUP BY tags.id, tags.name
          ORDER BY count DESC
          LIMIT ?", id, y, limit])
      tags = tags.sort_by { |t| t.name }
      tags.each { |t| t.name.gsub!("-", " ")}

      # I'm gonna compute the bins as:
      # bin_number = ((this_tag_frequency * bin_count)/max_tag_frequency).ceil
      # If max_tag_freqency < bin_count, we'll set
      # max_tag_frequency to bin_count -- this will keep tiny things from looking big.
      max_tag_freq = bin_count.to_i
      max_tag = tags.max {|a, b| a.count.to_i <=> b.count.to_i}
      max_tag_freq = max_tag.count.to_i if max_tag and max_tag.count.to_i > max_tag_freq

      tags.each do |t|
        yt = KeywordsHelper::TagDatum.new(t)
        yt.bin = ((t.count.to_f * bin_count.to_f)/max_tag_freq).ceil
        ydata.tags << yt
      end
      year_tags << ydata;
    end
    year_tags
  end
  
  def years_with_papers
    first = Record.find_by_sql([
      "SELECT min(pub_year) as year from citations
      join authorships on citations.id = authorships.id
      join people on authorships.person_id = people.id
      join memberships on people.id = memberships.person_id
      WHERE pub_year > 1500
      AND memberships.group_id = ?", id]
      )[0].year.to_i
    last = Record.find_by_sql([
      "SELECT max(pub_year) as year from citations
      join authorships on citations.id = authorships.id
      join people on authorships.person_id = people.id
      join memberships on people.id = memberships.person_id
      AND memberships.group_id = ?", id]
      )[0].year.to_i
      
    Range.new(first, last)
  end
  
  def popular_journals
    journals = Record.find_by_sql(
      ["SELECT count(c.id) as article_count, periodical_full from citations c
      join authorships au on au.citation_id = c.id
      join people p on au.person_id = p.id
      join memberships m on m.person_id = p.id
      join groups g on m.group_id = g.id
      where periodical_full != ''
      and citation_state_id = 3
      and g.id = ?
      group by periodical_full
      order by article_count DESC
      limit 10", id]
    )
  end
  
  def popular_publishers
    publishers = Record.find_by_sql(
      ["SELECT count(c.id) as article_count, publisher from citations c
      join authorships au on au.citation_id = c.id
      join people p on au.person_id = p.id
      join memberships m on m.person_id = p.id
      join groups g on m.group_id = g.id
      where publisher != ''
      and citation_state_id = 3
      and g.id = ?
      group by publisher
      order by article_count DESC
      limit 10", id]
    )
  end

  def people_who_have_published
    people = Person.find_by_sql(
      ["SELECT p.*, count(au.id) as pub_count FROM people p
        JOIN memberships m ON p.id = m.person_id
        JOIN groups g ON g.id = m.group_id
        JOIN authorships au ON p.id = au.person_id
        WHERE g.id = ? 
        GROUP BY p.id
        HAVING count(au.id) > 0
        ORDER BY p.last_name", id])
  end

  def citation_count
    citation_count = Record.find_by_sql(
      ["SELECT count(au.id) as count FROM people p
        JOIN memberships m ON p.id = m.person_id
        JOIN groups g ON g.id = m.group_id
        JOIN authorships au ON p.id = au.person_id
        WHERE g.id = ?", id])
  end

  def romeo_colours
    colors = Hash.new
    color_totals = Record.find_by_sql(
      ["select count(c.id) as count, pub.romeo_colour
      from citations c
      join authorships au on c.id = au.citation_id
      join people p on au.person_id = p.id
      join memberships m on m.person_id = p.id
      join groups g on m.group_id = g.id
      left join publications publ on c.publication_id = publ.id
      left join publishers pub on publ.publisher_id = pub.id
      where g.id = ?
      and c.periodical_full != ''
      and c.citation_state_id = 3
      group by pub.romeo_colour", id])
    color_totals.each do |color_info|
      colors[color_info.romeo_colour] = color_info.count.to_i
    end
  end
  
  def citations
    citations = Citation.find_by_sql(
      ["select c.* from citations c
      join authorships au on c.id = au.citation_id
      join people p on au.person_id = p.id
      join memberships m on p.id = m.person_id
      join groups g on m.group_id = g.id
      where g.id = ?
      limit 20", id]
    )
  end
end
