# frozen_string_literal: true

# Cleaner is a helper class that cleans data for both Word and Finder.
class Cleaner
  def initialize; end

  # for Word
  def clean(word)
    word.delete(' ').gsub(/\P{L}/, 'x').downcase
  end

  # for Finder
  def prepare(data)
    arr = data.split('Übersetzungen')
    cleaned = arr.shift.split(' (Deutsch)').pop
    arr.unshift(cleaned)
  end

  # for Finder
  def clean_table_text(str)
    arr = str.split
    arr.length > 7 ? arr.last(7).join(' ') : str
  end
end
