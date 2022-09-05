# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'net/http'

# Finder fetches the missing data for the word it is instantiated with.
class Finder
  attr_reader :word, :results

  def initialize(word)
    @word = convert_to_unicode(word)
    @results = []
    @cleaner = Cleaner.new
  end

  def find_artikel
    response = net_response(word)
    return results if response.include?('Not found')

    return results if regional_spelling?(response)

    # only_plural? must come before declinated_form? to filter correctly
    return results << 'Plural' if only_plural?(response)

    return results if declinated_form?(response)

    extract_artikel(response)
    results
  end

  private

  URL = 'https://de.wiktionary.org/wiki/'
  ARTIKEL = { 'm' => 'der',
              'n' => 'das',
              'f' => 'die' }.freeze
  UNICODE = {
    'ä' => '%C3%A4',
    'ö' => '%C3%B6',
    'ü' => '%C3%BC',
    'Ä' => '%C3%84',
    'Ö' => '%C3%96',
    'Ü' => '%C3%9C',
    'ß' => '%C3%9F'
  }.freeze

  # Method sets listed from last to first based on find_artikel flow
  #
  # 5. Extracting Artikel from pre-filtered data
  def extract_artikel(response)
    # if process_names resulted in an Array, the results are already adjusted
    return if process_names(response).is_a?(Array)

    @cleaner.headline_em(response).each do |element|
      results << ARTIKEL[element.text]
    end
  end

  def process_names(response)
    dataset_one = @cleaner.toc_element_text(response)
    dataset_two = @cleaner.headline_text(response)

    case_one = includes_any_names?(dataset_one)
    case_two = includes_any_names?(dataset_two)
    # special case for toponyms with only one meaning and 'Oder'
    case_three = (includes_toponyms?(dataset_two) && one_meaning?(dataset_two))
    exception = (word == 'Oder') # currently the only detected exception, hence handled here

    # returns a Nokogiri object, if no case for further processing applies
    return response if case_three || exception

    return response unless case_one || case_two

    case_one ? process(dataset_one) : results
  end

  def process(dataset)
    cleaned = @cleaner.prepare(dataset)
    cleaned.each do |unit|
      unless includes_any_names?(unit)
        unit.split(', ').each { |item| results << ARTIKEL[item] if ARTIKEL.key?(item) }
      end
    end
  end

  def includes_any_names?(dataset)
    dataset.include?('name') || dataset.include?('nym')
  end

  def includes_toponyms?(dataset)
    dataset.include?('nym')
  end

  def one_meaning?(dataset)
    dataset.split('Substantiv').length < 3
  end

  # 4. Checking for regional spelling
  def regional_spelling?(response)
    text = @cleaner.table_text(response)
    return false unless text.include?('andere Schreibung')

    results << text.split('.').first
    true
  end

  # 3. Checking if it's a declinated form
  def declinated_form?(response)
    text = @cleaner.table_text(response)
    return false unless text.include?('flektierte Form') && text.length < 400

    results << @cleaner.clean_table_text(text.split('.').first)
    true
  end

  # 2. Checking if it's a plural noun
  def only_plural?(response)
    no_genus_info?(response) && a_noun?(response) && not_a_name?(response)
  end

  def no_genus_info?(response)
    @cleaner.headline_em(response).empty?
  end

  def a_noun?(response)
    @cleaner.headline_text(response).include?('Substantiv')
  end

  def not_a_name?(response)
    !@cleaner.headline_text(response).include?('name')
  end

  # 1. Getting a response and processing it, if not 404
  def net_response(word)
    response = Net::HTTP.get_response(URI("#{URL}#{word}"))
    if response.code == '404'
      results << 'Not found'
    else
      html_content = URI.parse("#{URL}#{word}").open
      Nokogiri::HTML(html_content)
    end
  end

  # 0. Converting the word to Unicode (German special chars only)
  def convert_to_unicode(word)
    word.value.chars.map! { |char| UNICODE[char] || char }.join
  end
end
