require 'sinatra/base'
require 'rufus-scheduler'
require 'mongo'
require 'uri'
require 'bson'
require 'json'
require 'haml'
require 'pusher'
require 'chronic'
require 'helpers/helpers'
require 'services_runner'

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
  elsif ENV["RACK_ENV"] == 'test'
    conn = MongoClient.new("localhost", 27017)
    set :mongo_db, conn.db('realtime_benchmarks_test')
  else
    conn = MongoClient.new("localhost", 27017)
    set :mongo_db, conn.db('realtime_benchmarks')
  end

  configure do
    scheduler = Rufus::Scheduler.new(:max_work_threads => 10)
    set :scheduler, scheduler
    if ENV['MONGOHQ_URL']
      job = scheduler.schedule_every('5m', :first => "0.4s") do
        runner = ServicesRunner.new "heroku_tester"
        runner.run_benchmarks
        runner = nil
      end
    else
      job = scheduler.schedule_every('5m', :first => "0.4s") do
        runner = ServicesRunner.new "local_tester"
        runner.run_benchmarks
        runner = nil
      end
    end
  end

  Pusher.app_id = '66498'
  Pusher.key = 'a8536d1bddd6f5951242'
  Pusher.secret = '0c80607ae8d716a716bb'

  if ENV["RACK_ENV"] == 'test'
    $latencies_coll =  mongo_db['realtime_benchmarks_test']['latencies']
    $reliabilities_coll =  mongo_db['realtime_benchmarks_test']['reliabilities']
    $speeds_coll =  mongo_db['realtime_benchmarks_test']['speeds']
    $js_latencies_coll = mongo_db['realtime_benchmarks_test']['js_latencies']
  else
    $latencies_coll =  mongo_db['realtime_benchmarks']['latencies']
    $reliabilities_coll =  mongo_db['realtime_benchmarks']['reliabilities']
    $speeds_coll =  mongo_db['realtime_benchmarks']['speeds']
    $js_latencies_coll = mongo_db['realtime_benchmarks']['js_latencies']
  end

  get '/' do
    haml :index
  end

  post '/new_latency_data' do
    content_type :json
    since_time = Chronic.parse(params["since"])
    since_time ? latency_data = time_specific_data('latencies', since_time) : latency_data = last_day_data('latencies')
    combined_data = separated_latency_data(latency_data).to_json
  end

  post '/new_reliability_data' do
    content_type :json
    since_time = Chronic.parse(params["since"])
    since_time ? reliability_data = time_specific_data('reliabilities', since_time) : reliability_data = last_day_data('reliabilities')
    combined_data = separated_reliability_data(reliability_data).to_json
  end

  post '/new_js_latency_data' do
    content_type :json
    since_time = Chronic.parse(params["since"])
    since_time ? js_latency_data = time_specific_data('js_latencies', since_time) : js_latency_data = last_day_data('js_latencies')
    combined_data = separated_js_latency_data(js_latency_data).to_json
  end

  post '/new_speed_data' do
    content_type :json
    since_time = Chronic.parse(params["since"])
    since_time ? speed_data = time_specific_data('speeds', since_time) : speed_data = last_day_data('speeds')
    combined_data = separated_speed_data(speed_data).to_json
  end

  get '/reliability' do
    content_type :json
    since_time = Chronic.parse(params["since"])
    since_time ? reliability_data = time_specific_data('reliabilities', since_time) : reliability_data = last_day_data('reliabilities')
    combined_data = separated_reliability_data(reliability_data).to_json
  end

  get '/latency' do
    content_type :json
    since_time = Chronic.parse(params["since"])
    combined_data = nil
    if params["lang"] == "js" || params["lang"] == "javascript"
      since_time ? latency_data = time_specific_data('js_latencies', since_time) : latency_data = last_day_data('js_latencies')
      combined_data = separated_js_latency_data(latency_data)
    else
      since_time ? latency_data = time_specific_data('latencies', since_time) : latency_data = last_day_data('latencies')
      combined_data = separated_latency_data(latency_data)
    end

    latencies = []
    combined_data.each do |service|
      service = JSON.parse(service)
      num_values = service['values'].length
      if num_values > 0
        latencies << {
          service: service['key'],
          latency: service['values'].inject(0) { |memo, val| memo += val['y'].to_f;  } / num_values
        }
      else
        latencies << {
          service: service['key'],
          latency: -1
        }
      end
    end
    latencies.to_json
  end

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