ENV["RACK_ENV"] = 'test'
require './app'
require 'json'
require 'capybara'
require 'rack/test'
require 'capybara/poltergeist'
require 'selenium-webdriver'
require 'sinatra'

def app
  BenchmarkAnalysis
end

RSpec.configure do |config|
  
  config.include Rack::Test::Methods
  config.include Capybara::DSL

  Capybara.app = BenchmarkAnalysis
  Capybara.current_driver = :selenium
  Capybara.javascript_driver = :selenium

  # Capybara.current_driver = :poltergeist
  # Capybara.javascript_driver = :poltergeist

  config.before :each do
    $latencies_coll.drop
    $reliabilities_coll.drop
    $js_latencies_coll.drop
  end

  config.order = 'random'
end

def wait_for_dom(timeout = Capybara.default_wait_time)
  uuid = SecureRandom.uuid
  page.find("body")
  page.evaluate_script <<-EOS
    _.defer(function() {
      $('body').append("<div id='#{uuid}'></div>");
    });
  EOS
  page.find("##{uuid}")
end

def wait_for_ajax(timeout = Capybara.default_wait_time)
  page.wait_until(timeout) do
    page.evaluate_script 'jQuery.active == 0'
  end
end