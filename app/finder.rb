# frozen_string_literal: true

# Finder fetches the missing data for the word it is initialized with.
require 'nokogiri'
require 'open-uri'
require 'net/http'

class Finder
  attr_reader :word
  attr_accessor :results

  def initialize(word)
    @word = convert_to_unicode(word)
  end

  def find_data
    @results = []
    response = net_response(word)
    return results if response.include?('Not found')

    return results if regional_spelling?(response)

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
    text = response.search('#toc .toctext').text.strip
    return response unless text.include?('Nachname')

    arr = text.split('Übersetzungen')
    cleaned = arr.shift.split(' (Deutsch)').pop
    arr.unshift(cleaned).each do |data_unit|
      unless data_unit.include?('Nachname') || data_unit.include?('nym')
        data_unit.split(', ').each { |item| results << ARTIKEL[item] if ARTIKEL.key?(item) }
      end
    end
  end

  def regional_spelling?(response)
    content = response.search('#mw-content-text .mw-parser-output table').text.strip
    return false unless content.include?('andere Schreibung')

    results << content.split('.').first
    true
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
