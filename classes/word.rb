# frozen_string_literal: true

require_relative 'cleaner'

# Word is a base class that's currently assumed to be a noun with a
# @value provided by the user and @artikel set based on data fetched by Finder.
class Word
  attr_reader :value, :artikel

  def initialize(value)
    @value = Cleaner.clean(value).capitalize
  end

  def adjust_artikel(scraped_results)
    @artikel = scraped_results
  end
end
