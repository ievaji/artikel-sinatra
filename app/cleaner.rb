# frozen_string_literal: true

# Cleaner cleans data for both Word and Finder.
# It is a helper and is instantiated by other classes as needed.
class Cleaner
  def initialize; end

  def clean(word)
    word.delete(' ').gsub(/\P{L}/, 'x').downcase
  end

  def prepare(data)
    arr = data.split('Übersetzungen')
    cleaned = arr.shift.split(' (Deutsch)').pop
    arr.unshift(cleaned)
  end

  def clean_table_text(str)
    arr = str.split
    arr.length > 7 ? arr.last(7).join(' ') : str
  end
end
