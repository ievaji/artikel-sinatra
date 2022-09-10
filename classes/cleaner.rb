# frozen_string_literal: true

# Cleaner cleans data for both Word and Finder.
class Cleaner
  # Word : clean the value assigned to it
  def self.clean(str)
    str.gsub(/\P{L}/, ' ').delete(' ').downcase
  end

  # Finder : getting elements and their text
  def self.h3_headline_em(response)
    response.search('#mw-content-text h3 .mw-headline em')
  end

  def self.h3_headline_text(response)
    response.search('#mw-content-text h3 .mw-headline').text.strip
  end

  def self.h2_headline_text(response)
    response.search('#mw-content-text h2 .mw-headline').text
  end

  def self.toc_element_text(response)
    response.search('#toc .toctext').text.strip
  end

  def self.parser_output_table_text(response)
    response.search('#mw-content-text .mw-parser-output table').text.strip
  end

  def self.extract_table_data(response)
    arr = []
    response.search('.toclevel-1').each { |node| arr << node.text if node.text.include?('Deutsch') }
    result = arr.join.gsub(/(\n)+/, '*').split('*')
    first_case_empty?(response) ? exclude_irrelevent_data(result)[1..-1] : exclude_irrelevent_data(result)
  end

  def self.first_case_empty?(response)
    response.search('dd').first.text.include?('Abschnitt fehlt')
  end

  # Finder: processing extracted information
  def self.clean_parser_output(text)
    arr = text.gsub(/(\n)+/, '*').split('*')
    arr.length > 1 ? arr[1].split('.').first : arr.join.split('.').first
  end

  def self.filter(arr)
    stripped = arr.map { |str| str.gsub(/[0-9.]/, ' ').strip }

    stripped.length > 1 && stripped[1].length <= 16 ? [stripped.first] : stripped
  end

  def self.exclude_irrelevent_data(arr)
    result = []
    arr.each { |str| result << str if relevant?(str) }
    result[1..-1]
  end

  def self.relevant?(str)
    !str.include?('Übersetzung') && !str.include?('Vorname') && !str.include?('Nachname') &&
      !str.include?('Abkürzung') && !str.include?('Deklinierte Form')
  end
end
