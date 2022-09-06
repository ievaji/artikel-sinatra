# frozen_string_literal: true

# Cleaner cleans data for both Word and Finder.
class Cleaner
  # Word : initialize : clean the value assigned to it
  def self.clean(str)
    str.gsub(/\P{L}/, ' ').delete(' ').downcase
  end

  # Finder : exclude_names : clean the first element of a dataset
  def self.prepare(str)
    arr = str.split('Übersetzungen')
    cleaned = arr.shift.split(' (Deutsch)').pop
    arr.unshift(cleaned)
  end

  # Finder : various methods : getting elements and their text
  def self.h3_headline_em(response)
    response.search('#mw-content-text h3 .mw-headline em')
  end

  def self.h3_headline_text(response)
    response.search('#mw-content-text h3 .mw-headline').text.strip
  end

  def self.toc_element_text(response)
    response.search('#toc .toctext').text.strip
  end

  def self.parser_output_table_text(response)
    response.search('#mw-content-text .mw-parser-output table').text.strip
  end

  def self.clean_info(text)
    arr = text.gsub(/(\n)+/, '*').split('*')
    arr.length > 1 ? arr[1].split('.').first : arr.join.split('.').first
  end

  # new methods for the refactored Finder
  def self.extract_table_data(response)
    arr = []
    response.search('.toclevel-1').each { |node| arr << node.text if node.text.include?('Deutsch') }
    result = arr.join.gsub(/(\n)+/, '*').split('*')
    exclude_irrelevent_data(result)
  end

  def self.exclude_irrelevent_data(arr)
    result = []
    arr.each { |str| result << str if relevant?(str) }
    result[1..-1]
  end

  def self.relevant?(str)
    !str.include?('Übersetzung') && !str.include?('Vorname') && !str.include?('Nachname') &&
      !str.include?('Abkürzung')
  end
end
