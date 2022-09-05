# frozen_string_literal: true

# Cleaner cleans data for both Word and Finder.
class Cleaner
  def initialize; end

  # Word : initialize : clean the value assigned to it
  def clean(str)
    str.delete(' ').gsub(/\P{L}/, 'x').downcase
  end

  # Finder : exclude_names : clean the first element of a dataset
  def prepare(str)
    arr = str.split('Übersetzungen')
    cleaned = arr.shift.split(' (Deutsch)').pop
    arr.unshift(cleaned)
  end

  # Finder : various methods : getting elements and their text
  def headline_em(response)
    response.search('#mw-content-text h3 .mw-headline em')
  end

  def headline_text(response)
    response.search('#mw-content-text h3 .mw-headline').text.strip
  end

  def toc_element_text(response)
    response.search('#toc .toctext').text.strip
  end

  def table_text(response)
    response.search('#mw-content-text .mw-parser-output table').text.strip
  end

  def clean_table_text(str)
    arr = str.split
    arr.length > 7 ? arr.last(7).join(' ') : str
  end
end
