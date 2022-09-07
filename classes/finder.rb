# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'net/http'

# Finder fetches the missing data for the word it is instantiated with.
class Finder
  attr_reader :word, :results, :response

  def initialize(str)
    # this instance var is only referenced once. however, there it is imo the quickest option.
    @word = convert_to_unicode(str)
    @results = []
    # net_response already modifies results, if response.code == 404
    @response = net_response(word)
  end

  def find_artikel
    return results if results.include?('Not found')

    several_meanings? ? process_content_table : process_page_content

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

  def several_meanings?
    !response.search('.toclevel-1').empty?
  end

  # Scenario 1: several_meanings == true
  def process_content_table
    data = Cleaner.extract_table_data(response)
    return if data.empty?

    only_toponyms?(data) ? include_toponyms(data) : exclude_toponyms(data)
  end

  def only_toponyms?(data)
    # Oder is an exception and must pass this filter
    data.first.include?('Toponym') || word == 'Oder'
  end

  def include_toponyms(arr)
    # the check is based on the logic that Deklinierte Form which also would produce nil
    # will only ever come first when it is the only meaning. hence this checks for Plural
    # in case of several meanings: if 1st element has no Genus symbol, it must be Plural.
    return results << 'Plural' if first_meaning_plural?(arr)

    # OLD CODE :
    arr.each do |str|
      key = str.split(', ')[1]
      results << ARTIKEL[key] unless key.nil?
    end
    #
    # PROBLEM with OLD CODE: would not include any further Genus data beyond [1]
    #
    # NEW CODE:
    # arr.each do |str|
    #   str.split(', ').each do |e|
    #     results << ARTIKEL[e] if ARTIKEL.key?(e)
    #   end
    # end
    #
    # PROBLEM with NEW CODE: slower
  end

  def exclude_toponyms(arr)
    return results << 'Plural' if first_meaning_plural?(arr)

    filtered = Cleaner.filter_regionalisms(arr)

    # OLD CODE :
    filtered.each do |str|
      key = str.split(', ')[1] unless str.include?('Toponym')
      results << ARTIKEL[key] unless key.nil?
    end
    #
    # PROBLEM with OLD CODE: would not include any further Genus data beyond [1]
    #
    # NEW CODE:
    # arr.each do |str|
    #   unless str.include?('Toponym')
    #     str.split(', ').each do |e|
    #       results << ARTIKEL[e] if ARTIKEL.key?(e)
    #     end
    #   end
    # end
    #
    # PROBLEM with NEW CODE: slower
  end

  def first_meaning_plural?(arr)
    first = arr.first.split(', ')
    !first.include?('m') && !first.include?('n') && !first.include?('f')
  end

  # Scenario 2: several_meanings == false
  def process_page_content
    return if !Cleaner.h2_headline_text(response).include?('Deutsch')

    return results << 'Plural' if plural_noun?

    text = Cleaner.parser_output_table_text(response)

    exception?(text) ? extract_info(text) : extract_artikel
  end

  def plural_noun?
    text = Cleaner.h3_headline_text(response)
    arr = text.split(', ')
    arr.include?('Substantiv') && not_a_name?(arr) && no_genus?(arr)
  end

  def no_genus?(arr)
    !arr.include?('m') && !arr.include?('n') && !arr.include?('f')
  end

  def not_a_name?(arr)
    !arr.include?('Nachname') && !arr.include?('Vorname')
  end

  def exception?(text)
    text.include?('andere Schreibung') ||
      text.include?('flektierte Form') && text.length < 400
  end

  def extract_info(text)
    results << Cleaner.clean_info(text)
  end

  def extract_artikel
    headline = Cleaner.h3_headline_text(response)
    return if headline.include?('Vorname') || headline.include?('Nachname')

    Cleaner.h3_headline_em(response).each do |element|
      results << ARTIKEL[element.text]
    end
  end

  # Basic setup
  def net_response(str)
    response = Net::HTTP.get_response(URI("#{URL}#{str}"))
    if response.code == '404'
      results << 'Not found'
    else
      html_content = URI.parse("#{URL}#{str}").open
      Nokogiri::HTML(html_content)
    end
  end

  def convert_to_unicode(str)
    str.chars.map! { |char| UNICODE[char] || char }.join
  end
end
