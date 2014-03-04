ENV["RACK_ENV"] = 'test'
require './app'
require 'json'
require 'capybara'
require 'rack/test'
require 'capybara/poltergeist'
require 'sinatra'

def app
  BenchmarkAnalysis
end

Capybara.app = Sinatra::Application
Capybara.javascript_driver = :poltergeist

RSpec.configure do |config|
  
  config.include Rack::Test::Methods
  config.include Capybara::DSL

  config.order = 'random'
end



