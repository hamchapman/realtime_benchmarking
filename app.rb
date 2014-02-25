require 'sinatra/base'
require 'rufus-scheduler'
require 'mongo'
require 'bson'
require 'json'
require 'haml'
require 'pusher'
require './lib/pusher'
require './lib/realtime_co'
require './lib/pubnub'
require './lib/services_runner'

class CompetitorAnalysisTesting < Sinatra::Base

  include Mongo

  configure do
    conn = MongoClient.new("localhost", 27017)
    set :mongo_connection, conn
    set :mongo_db, conn.db('test')

    $latencies_coll =  mongo_db['competitor_benchmarks']['latencies']
    
    scheduler = Rufus::Scheduler.new
    set :scheduler, scheduler
    # scheduler.every('30s') do
    #   puts "Running tests"
    #   runner = ServicesRunner.new "tester"
    #   runner.benchmark_latencies
    # end
  end

  Pusher.app_id = '66498'
  Pusher.key = 'a8536d1bddd6f5951242'
  Pusher.secret = '0c80607ae8d716a716bb'

  get '/' do 
    graph_data = settings.mongo_db['competitor_benchmarks']['latencies'].find.to_a
    @pusher_data = retrieve_data_for "pusher", '#ff7f0e', graph_data
    @pubnub_data = retrieve_data_for "pubnub", '#3c9fad', graph_data

    puts @pusher_data.inspect
    haml :index
  end

  get '/latency_test' do
    # rtc = RealtimeCoBenchmarker.new "chicken"
    # sleep 2
    # rtc.connect
    # sleep 2
    # rtc.send({ time: Time.now })
  end

  get '/new_data' do
    content_type :json
    graph_data = settings.mongo_db['competitor_benchmarks']['latencies'].find.to_a
    @pusher_updated_data = retrieve_data_for "pusher", '#ff7f0e', graph_data
    @pubnub_updated_data = retrieve_data_for "pubnub", '#3c9fad', graph_data
    combined_data = [@pusher_updated_data, @pubnub_updated_data].to_json
  end
  

  post '/pusher/auth' do
    response = Pusher[params[:channel_name]].authenticate(params[:socket_id])
    content_type :json
    return response.to_json
  end

  helpers do
    def retrieve_data_for service, colour, data
      service_data = data.select { |entry| entry['service'] == service }
      service_data.each do |hash|
        hash[:x] = hash.delete "time"
        hash[:y] = hash.delete "latency"
        hash.delete "_id"
        hash.delete "service"
      end

      { values: service_data, key: service, color: colour }.to_json
    end
  end

  run! if app_file == $0
end