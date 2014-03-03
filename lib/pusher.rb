require 'pusher'
require 'pusher-client'
require 'json'

class PusherBenchmarker

  attr_reader :ready, :ready_for_next_tests

  def initialize channel
    @channel = channel
    setup
    @benchmarks = []
    @ready = false

    @client.bind("pusher:connection_established") do |data|
      subscribe      
    end

    @client.bind('pusher_internal:subscription_succeeded') do |data|
      @ready = true  
    end

    connect
  end

  def setup
    @client = PusherClient::Socket.new(Pusher.key)
  end

  def connect
    @client.connect(true)
  end

  def disconnect
    @client.disconnect
  end

  def subscribe
    @client.subscribe(@channel)
    @subscribed = true
    @client[@channel].bind('benchmark') do |data|
      sent = Time.parse(JSON.parse(data)["time"]).to_f
      received = Time.now.to_f
      latency = (received - sent) * 1000
      # puts latency
      puts data.inspect
      @benchmarks << { service: "pusher", time: Time.now, latency: latency }
    end
  end

  def unsubscribe
    @client.unsubscribe @channel
    @ready = false
  end
    
  def send message
    Pusher.trigger(@channel, 'benchmark', message)
  end

  def benchmark_latency
    while (!ready)
      sleep(1)
    end
    (1..20).each do |num|
      send({time: Time.now, id: num})
      sleep 0.2
    end
    sleep 2.0
    $latencies_coll.insert( { service: "pusher", time: Time.now, latency: average_latency } )
    Pusher.trigger('mongo', 'latencies-update', 'Mongo updated')
    # puts @benchmarks.inspect
    @benchmarks = []
  end

  def average_latency
    @benchmarks.inject(0) { |memo, obj| memo += obj[:latency] } / @benchmarks.length
  end


  def benchmark_reliability
    while (!ready)
      sleep(1)
    end
    (1..20).each do |num|
      send({time: Time.now, id: num})
      sleep 0.2
    end
    sleep 2.0
    $reliabilities_coll.insert( { service: "pusher", time: Time.now, reliability: calculate_reliability_percentage } )
    Pusher.trigger('mongo', 'reliabilities-update', 'Mongo updated')
    @benchmarks = []
    # puts @benchmarks.inspect
    reset_client
  end

  def calculate_reliability_percentage
    (@benchmarks.length / 20.0) * 100
  end

  def benchmark_speed
    puts @client
  end

  def reset_client
    unsubscribe
    disconnect
    @client = nil
  end
  
end