require 'sinatra/base'
require 'rufus-scheduler'
require 'mongo'
require 'uri'
require 'bson'
require 'json'
require 'haml'
require 'pusher'
require 'chronic'
require './lib/pusher'
require './lib/realtime_co'
require './lib/pubnub'
require './lib/services_runner'

class BenchmarkAnalysis < Sinatra::Base

  @@pusher_colour = '#ff7f0e'
  @@pubnub_colour = '#3c9fad'
  @@realtime_co_colour = '#ad007b'

  include Mongo

  def get_connection
    return @mongo_db if @mongo_db
    db = URI.parse(ENV['MONGOHQ_URL'])
    db_name = db.path.gsub(/^\//, '')
    db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
    db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
    db_connection
  end
  
  # SOMETHING LIKE THIS TO SETUP HEROKU / LOCALLY 

  if ENV['MONGOHQ_URL']
    set :mongo_db, get_connection
  else
    conn = MongoClient.new("localhost", 27017)
    set :mongo_db, conn.db('test')
  end
    
  configure do
    scheduler = Rufus::Scheduler.new
    set :scheduler, scheduler
    scheduler.every('1m') do
      puts "Running tests"
      runner = ServicesRunner.new "tester"
      runner.run_benchmarks
    end
  end

  # configure do
  #   conn = MongoClient.new("localhost", 27017)
  #   # set :mongo_connection, conn
  #   set :mongo_db, conn.db('test')

  #   $latencies_coll =  mongo_db['competitor_benchmarks']['latencies']
  #   $reliabilities_coll =  mongo_db['competitor_benchmarks']['reliabilities']
    
  #   scheduler = Rufus::Scheduler.new
  #   set :scheduler, scheduler
  #   scheduler.every('1m') do
  #     puts "Running tests"
  #     runner = ServicesRunner.new "tester"
  #     runner.run_benchmarks
  #   end
  # end

  Pusher.app_id = '66498'
  Pusher.key = 'a8536d1bddd6f5951242'
  Pusher.secret = '0c80607ae8d716a716bb'

  $latencies_coll =  mongo_db['competitor_benchmarks']['latencies']
  $reliabilities_coll =  mongo_db['competitor_benchmarks']['reliabilities']

  get '/' do 
    latency_data = settings.mongo_db['competitor_benchmarks']['latencies'].find({}, sort: ["time", 1]).to_a
    @pusher_latency = latency_data_for 'pusher', @@pusher_colour, latency_data
    @pubnub_latency = latency_data_for 'pubnub', @@pubnub_colour, latency_data
    @realtime_co_latency = latency_data_for 'realtime_co', @@realtime_co_colour, latency_data

    reliability_data = settings.mongo_db['competitor_benchmarks']['reliabilities'].find({}, sort: ["time", 1]).to_a
    @pusher_reliability = reliability_data_for 'pusher', @@pusher_colour, reliability_data
    @pubnub_reliability = reliability_data_for 'pubnub', @@pubnub_colour, reliability_data
    @realtime_co_reliability = reliability_data_for 'realtime_co', @@realtime_co_colour, reliability_data

    haml :index
  end

  post '/new_data' do
    content_type :json
    since_time = Chronic.parse(params["since"])
    if since_time
      latency_data = settings.mongo_db['competitor_benchmarks']['latencies'].find({ time: { "$gt" => since_time } }, sort: ["time", 1]).to_a
    else
      latency_data = settings.mongo_db['competitor_benchmarks']['latencies'].find({ time: { "$gt" => Time.now - 7*24*60*60 } }, sort: ["time", 1]).to_a
    end
    @pusher_updated_latency = latency_data_for 'pusher', @@pusher_colour, latency_data
    @pubnub_updated_latency = latency_data_for 'pubnub', @@pubnub_colour, latency_data
    @realtime_co_updated_latency = latency_data_for 'realtime_co', @@realtime_co_colour, latency_data
    combined_data = [@pusher_updated_latency, @pubnub_updated_latency, @realtime_co_updated_latency].to_json
  end
  

  post '/pusher/auth' do
    response = Pusher[params[:channel_name]].authenticate(params[:socket_id])
    content_type :json
    return response.to_json
  end

  helpers do
    def latency_data_for service, colour, data
      service_data = data.select { |entry| entry['service'] == service }
      service_data.each do |hash|
        hash[:x] = hash.delete "time"
        hash[:y] = hash.delete "latency"
        hash.delete "_id"
        hash.delete "service"
      end

      { values: service_data, key: service, color: colour }.to_json
    end

    def reliability_data_for service, colour, data
      service_data = data.select { |entry| entry['service'] == service }
      reliability = service_data.inject(0) { |memo, obj| memo += obj['reliability'] } / service_data.length

      { service: service, reliability: reliability, color: colour }.to_json
    end
  end

  run! if app_file == $0
end