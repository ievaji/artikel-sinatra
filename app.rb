# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'pry-byebug'
require 'better_errors'

configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = File.expand_path(__dir__)
end

require_relative 'classes/word'
require_relative 'classes/finder'

get '/' do
  erb :home
end

post '/' do
  @word = Word.new(params[:word])
  finder = Finder.new(@word)
  data = finder.find_artikel
  @word.adjust_artikel(data)
  erb :show
end
