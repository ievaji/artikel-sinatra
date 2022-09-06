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
  end

  def find_artikel
    response = net_response(word)
    return results if response.include?('Not found')

    several_meanings?(response) ? process_content_table(response) : process_content(response)

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

  def several_meanings?(response)
    !response.search('.toclevel-1').empty?
  end

  # Scenario 1: several_meanings == true
  def process_content_table(response)
    data = Cleaner.extract_table_data(response)
    return if data.empty?

    only_toponyms?(data) ? include_toponyms(data) : exclude_toponyms(data)
  end

  def only_toponyms?(data)
    # Oder is an exception and must pass this filter
    data.first.include?('Toponym') || word == 'Oder'
  end

  def include_toponyms(arr)
    # results << 'Plural' if first_meaning_plural?(arr)
    arr.each do |str|
      key = str.split(', ')[1]
      results << ARTIKEL[key] unless key.nil?
    end
  end

  def exclude_toponyms(arr)
    # the check is based on the logic that Deklinierte Form which also would produce nil
    # will only ever come first when it is the only meaning. hence this checks for Plural
    # in case of several meanings: if 1st element has no Genus symbol, it must be Plural.
    results << 'Plural' if first_meaning_plural?(arr)
    arr.each do |str|
      key = str.split(', ')[1] unless str.include?('Toponym')
      results << ARTIKEL[key] unless key.nil?
    end
  end

  def first_meaning_plural?(arr)
    first = arr.first.split(', ') # [1].nil?
    !first.include?('m') && !first.include?('n') && !first.include?('f')
  end

  # Scenario 2: several_meanings == false
  def process_content(response)
    return results << 'Plural' if plural_noun?(response)

    text = Cleaner.parser_output_table_text(response)

    exception?(text) ? extract_info(text) : extract_artikel(response)
  end

  def plural_noun?(response)
    text = Cleaner.h3_headline_text(response)
    # text.split(', ').length < 2 && text.include?('Substantiv')
    arr = text.split(', ')
    !arr.include?('m') && !arr.include?('n') && !arr.include?('f') && arr.include?('Substantiv')
  end

  def exception?(text)
    text.include?('andere Schreibung') ||
      text.include?('flektierte Form') && text.length < 400
  end

  def extract_info(text)
    results << Cleaner.clean_info(text)
  end

  def extract_artikel(response)
    headline = Cleaner.h3_headline_text(response)
    return if headline.include?('Vorname') || headline.include?('Nachname')

    Cleaner.h3_headline_em(response).each do |element|
      results << ARTIKEL[element.text]
    end
  end

  # Basic setup
  def net_response(word)
    response = Net::HTTP.get_response(URI("#{URL}#{word}"))
    if response.code == '404'
      results << 'Not found'
    else
      html_content = URI.parse("#{URL}#{word}").open
      Nokogiri::HTML(html_content)
    end
  end

  def convert_to_unicode(word)
    word.value.chars.map! { |char| UNICODE[char] || char }.join
  end
end
