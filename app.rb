require 'sinatra/base'
require 'rufus-scheduler'
require 'mongo'
require 'uri'
require 'bson'
require 'json'
require 'haml'
require 'pusher'
require 'chronic'
require './lib/helpers/helpers'
require './lib/pusher'
require './lib/realtime_co'
require './lib/pubnub'
require './lib/services_runner'

class BenchmarkAnalysis < Sinatra::Base

  helpers ApplicationHelper
  include Mongo

  $pusher_colour = '#ff7f0e'
  $pubnub_colour = '#3c9fad'
  $realtime_co_colour = '#ad007b'
  $goinstant_colour = '#0022e2'
  $firebase_colour = '#00b109'

  if ENV['MONGOHQ_URL']
    require 'newrelic_rpm'
    db = URI.parse(ENV['MONGOHQ_URL'])
    db_name = db.path.gsub(/^\//, '')
    db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
    db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
    db_connection
    set :mongo_db, db_connection
  else
    conn = MongoClient.new("localhost", 27017)
    set :mongo_db, conn.db('realtime_benchmarks')
  end
    
  configure do
    scheduler = Rufus::Scheduler.new
    set :scheduler, scheduler
    if ENV['MONGOHQ_URL']
      scheduler.every('5m') do
        puts "Running tests"
        runner = ServicesRunner.new "heroku_tester"
        runner.run_benchmarks
      end
    else
      scheduler.every('1m') do
        puts "Running tests"
        runner = ServicesRunner.new "local_tester"
        runner.run_benchmarks
      end
    end
  end

  Pusher.app_id = '66498'
  Pusher.key = 'a8536d1bddd6f5951242'
  Pusher.secret = '0c80607ae8d716a716bb'

  $latencies_coll =  mongo_db['realtime_benchmarks']['latencies']
  $reliabilities_coll =  mongo_db['realtime_benchmarks']['reliabilities']
  $speeds_coll =  mongo_db['realtime_benchmarks']['speeds']
  $js_latencies_coll = mongo_db['realtime_benchmarks']['js_latencies']

  get '/' do 
    latency_data = last_week_data 'latencies'
    @pusher_latency = latency_data_for 'pusher', $pusher_colour, latency_data
    @pubnub_latency = latency_data_for 'pubnub', $pubnub_colour, latency_data
    @realtime_co_latency = latency_data_for 'realtime_co', $realtime_co_colour, latency_data

    reliability_data = last_week_data 'reliabilities'
    @pusher_reliability = reliability_data_for 'pusher', $pusher_colour, reliability_data
    @pubnub_reliability = reliability_data_for 'pubnub', $pubnub_colour, reliability_data
    @realtime_co_reliability = reliability_data_for 'realtime_co', $realtime_co_colour, reliability_data

    js_latency_data = last_week_data 'js_latencies'
    @pusher_js_latency = latency_data_for 'pusher', $pusher_colour, js_latency_data
    @pubnub_js_latency = latency_data_for 'pubnub', $pubnub_colour, js_latency_data
    @realtime_co_js_latency = latency_data_for 'realtimeco', $realtime_co_colour, js_latency_data
    @goinstant_js_latency = latency_data_for 'goinstant', $goinstant_colour, js_latency_data
    @firebase_js_latency = latency_data_for 'firebase', $firebase_colour, js_latency_data

    haml :index
  end

  post '/new_latency_data' do
    content_type :json
    since_time = Chronic.parse(params["since"])
    if since_time
      latency_data = time_specific_data 'latencies', since_time
    else
      latency_data = last_week_data 'latencies'
    end
    combined_data = separated_latency_data(latency_data).to_json
  end

  post '/new_reliability_data' do
    content_type :json
    since_time = Chronic.parse(params["since"])
    if since_time
      reliability_data = time_specific_data 'reliabilities', since_time
    else
      reliability_data = last_week_data 'reliabilities'
    end
    combined_data = seperated_realiability_data(reliability_data).to_json
  end

  post '/new_js_latency_data' do
    content_type :json
    since_time = Chronic.parse(params["since"])
    if since_time
      js_latency_data = time_specific_data 'js_latencies', since_time
    else
      js_latency_data = last_week_data 'js_latencies'
    end
    combined_data = separated_js_latency_data(js_latency_data).to_json
  end

  # post '/new_speed_data' do
  #   content_type :json
  #   since_time = Chronic.parse(params["since"])
  #   if since_time
  #     speed_data = settings.mongo_db['realtime_benchmarks']['speeds'].find({ time: { "$gt" => since_time } }, sort: ["time", 1]).to_a
  #   else
  #     speed_data = settings.mongo_db['realtime_benchmarks']['speeds'].find({ time: { "$gt" => Time.now - 7*24*60*60 } }, sort: ["time", 1]).to_a
  #   end
  #   combined_data = seperated_speed_data(speed_data).to_json
  # end

  get '/js_latencies' do
    haml :js_latencies
  end

  post '/test' do
    content_type :json
    latencies = params["latencies"]
    save_latencies_to_db latencies
    Pusher.trigger('mongo', 'js-latencies-update', 'Mongo updated')
  end

  post '/pusher/auth' do
    response = Pusher[params[:channel_name]].authenticate(params[:socket_id])
    content_type :json
    return response.to_json
  end

  run! if app_file == $0
end