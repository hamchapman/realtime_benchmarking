require 'sinatra/base'
require 'redis'
require 'mongo'
require 'bson'
require 'json'
require 'haml'
require 'pusher'

class CompetitorAnalysisTesting < Sinatra::Base

  include Mongo

  configure do
    conn = MongoClient.new("localhost", 27017)
    set :mongo_connection, conn
    set :mongo_db, conn.db('test')
  end

  Pusher.app_id = '66498'
  Pusher.key = 'a8536d1bddd6f5951242'
  Pusher.secret = '0c80607ae8d716a716bb'

  get '/' do 
    haml :index 
  end

  post '/new_benchmark' do
    content_type :json
    new_id = settings.mongo_db['test'].insert params
    puts "Saving to mongo"
  end

  post '/pusher/auth' do
    response = Pusher[params[:channel_name]].authenticate(params[:socket_id])
    content_type :json
    return response.to_json
  end

  helpers do
    def document_by_id id
      id = object_id(id) if String === id
      settings.mongo_db['test'].find_one(:_id => id).to_json
    end
  end

  run! if app_file == $0
end


# var sent_time = new Date();
# var data = { time: JSON.stringify(sent_time), service: "GoInstant" };
# $.ajax({
#   type: 'POST',
#   url: '/new_benchmark',
#   data: data
# });