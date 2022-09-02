# frozen_string_literal: true

require_relative 'cleaner'

# Word is a base class that's currently a noun with a @value provided by the user
# and an @artikel attribute set based on data fetched by Finder.
class Word
  attr_reader :value, :artikel

  def initialize(value)
    cleaner = Cleaner.new
    @value = cleaner.clean(value).capitalize
  end

  def adjust_artikel(scraped_results)
    @artikel = scraped_results
  end
end
