# frozen_string_literal: true

require_relative 'cleaner'

# Word is a base class that's currently a noun with a @value provided by the user
# and an @artikel attribute set based on data fetched by Finder.
class Word
  attr_reader :value, :artikel

  # EXCEPTIONS = { 'vereinigtestaaten' => 'Vereinigte_Staaten' }.freeze

  def initialize(value)
    # cleaned = Cleaner.clean(value)
    # checked = EXCEPTIONS.key?(cleaned) ? EXCEPTIONS[cleaned] : cleaned.capitalize
    # @value = checked
    @value = Cleaner.clean(value).capitalize
  end

  def adjust_artikel(scraped_results)
    @artikel = scraped_results
  end
end
