# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'net/http'

# Finder fetches the missing data for the word it is initialized with.
class Finder
  attr_reader :word
  attr_accessor :results

  def initialize(word)
    @word = convert_to_unicode(word)
    @cleaner = Cleaner.new
    @results = []
  end

  def find_artikel
    response = net_response(word)
    return results if response.include?('Not found')

    return results if regional_spelling?(response)

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

  def extract_artikel(response)
    return unless exclude_last_names(response).is_a?(Nokogiri::HTML4::Document)

    response.search('#mw-content-text h3 .mw-headline em').each do |element|
      results << ARTIKEL[element.text]
    end
  end

  def exclude_last_names(response)
    data = response.search('#toc .toctext').text.strip
    return response unless data.include?('Nachname')

    cleaned = @cleaner.prepare(data)
    cleaned.each do |unit|
      unless unit.include?('Nachname') || unit.include?('nym')
        unit.split(', ').each { |item| results << ARTIKEL[item] if ARTIKEL.key?(item) }
      end
    end
  end

  def regional_spelling?(response)
    text = extract_table_text(response)
    return false unless text.include?('andere Schreibung')

    results << text.split('.').first
    true
  end

  def declinated_form?(response)
    text = extract_table_text(response)
    return false unless text.include?('flektierte Form')

    results << @cleaner.clean_table_text(text.split('.').first)
    true
  end

  def extract_table_text(response)
    response.search('#mw-content-text .mw-parser-output table').text.strip
  end

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
