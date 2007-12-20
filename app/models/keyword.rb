class Keyword
  
  def self.tags(group_id, limit)
    if group_id != 0
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
          LIMIT ?", group_id, limit]
      )
    else
      tags = Tag.find_by_sql(
        ["SELECT tags.id, tags.name, count(*) as count
          FROM tags
            JOIN taggings ON tags.id = taggings.tag_id
            JOIN citations ON taggings.taggable_id = citations.id
            JOIN authorships ON citations.id = authorships.citation_id
            JOIN people ON authorships.person_id = people.id
            JOIN memberships ON people.id = memberships.person_id
          GROUP BY tags.id, tags.name
          ORDER BY count DESC
          LIMIT ?", limit]
      )
    end
  end

  # TODO: Refactor ALL OF THIS SHIT to make it generalize to People, Departments, Colleges, or the
  # system-at-large.
  # Really, this should see Tags changed into more Keyword and Keywording models,
  # and the Keywording model would handle this stuff.
  # Keywords would specifically be applied from database controlled vocabs, possibly
  # with stoplists and synonym rings and such... and be specifically knowlegable about
  # Citations and the like.

  # For now, department-only support is pretty bad-ass.

  def self.tags_by_year(limit = 25, bin_count = 5)
    tags_for_years(years_with_papers, limit, bin_count).reject { |ydata| ydata.tags.size < 1 }
  end

  def self.tags_for_years(year_range, limit = 25, bin_count = 5)
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
  
  def self.years_with_papers(group_id)
    first = Record.find_by_sql([
      "SELECT min(pub_year) as year from citations
      join authorships on citations.id = authorships.id
      join people on authorships.person_id = people.id
      join memberships on people.id = memberships.person_id
      WHERE pub_year > 1500
      AND memberships.group_id = ?", group_id]
      )[0].year.to_i
    last = Record.find_by_sql([
      "SELECT max(pub_year) as year from citations
      join authorships on citations.id = authorships.id
      join people on authorships.person_id = people.id
      join memberships on people.id = memberships.person_id
      AND memberships.group_id = ?", group_id]
      )[0].year.to_i
      
    Range.new(first, last)
  end
end
