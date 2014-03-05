require 'simplecov'
SimpleCov.start
ENV["RACK_ENV"] = 'test'
require './app'
require 'json'
require 'capybara'
require 'rack/test'
require 'capybara/poltergeist'
require 'selenium-webdriver'
require 'sinatra'
require 'net/https'
require 'chronic'

def app
  BenchmarkAnalysis
end

RSpec.configure do |config|
  
  config.include Rack::Test::Methods
  config.include Capybara::DSL

  Capybara.app = BenchmarkAnalysis
  Capybara.current_driver = :selenium
  Capybara.javascript_driver = :selenium

  config.before :each do
    $latencies_coll.drop
    $reliabilities_coll.drop
    $js_latencies_coll.drop
  end

  config.order = 'random'
end