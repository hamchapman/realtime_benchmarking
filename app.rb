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
    # scheduler.every('20s') do
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
    pusher_data = graph_data.select { |entry| entry['service'] == 'pusher' }
    pusher_data.each do |hash| 
      hash[:x] = hash.delete "time"
      hash[:y] = hash.delete "latency"
      hash.delete "_id"
      hash.delete "service"
    end

    @pusher_data_for_d3 = [ { values: pusher_data, key: 'Pusher', color: '#ff7f0e' } ]

    puts pusher_data.inspect
    haml :index, :locals => { pusher_data: @pusher_data_for_d3 }
  end

  get '/latency_test' do
    # pb = PusherBenchmarker.new "chicken"
    # sleep 1.0
    # pb.send({ time: Time.now })
    # sleep 1
    # settings.mongo_db['test'].insert({test: "1382"})
    # $latencies.insert({time: Time.now, latency: 1398})
    # rtc = RealtimeCoBenchmarker.new "chicken"
    # sleep 2
    # rtc.connect
    # sleep 2
    # rtc.send({ time: Time.now })
    # sleep 1
    # pn = PubnubBenchmarker.new "chicken"
    # sleep 1
    # pn.send({ time: Time.now })
  end

  # post '/new_benchmark' do
  #   content_type :json
  #   new_id = settings.mongo_db['test'].insert params
  #   puts "Saving to mongo"
  # end

  post '/pusher/auth' do
    response = Pusher[params[:channel_name]].authenticate(params[:socket_id])
    content_type :json
    return response.to_json
  end

  # helpers do
  #   def document_by_id id
  #     id = object_id(id) if String === id
  #     settings.mongo_db['latnecies'].find_one(:_id => id).to_json
  #   end
  # end

  run! if app_file == $0
end