require 'pusher'
require 'pusher-client'
require 'json'

class PusherBenchmarker

  attr_reader :ready

  def initialize channel
    @channel = channel
    setup
    @latency_benchmarks = []
    @ready = false

    @client.bind("pusher:connection_established") do |data|
      puts "Connected"
      subscribe      
    end

    @client.bind('pusher_internal:subscription_succeeded') do |data|
      puts "Subscribed"
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

  def subscribe
    @client[@channel].bind('pusher:subscription_succeeded') do |data|
    end
    @client.subscribe(@channel)
    @subscribed = true
    @client[@channel].bind('benchmark') do |data|
      sent = Time.parse(JSON.parse(data)["time"]).to_f
      received = Time.now.to_f
      latency = (received - sent) * 1000
      puts latency
      puts data.inspect
      @latency_benchmarks << { service: "pusher", time: Time.now, latency: latency }
    end
  end

  def unsubscribe
    @client.unsubscribe @channel
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
    end
    $latencies_coll.insert( { service: "pusher", time: Time.now, latency: average_latency } )
    @latency_benchmarks = []
    unsubscribe
    @client = nil
  end

  def average_latency
    puts @latency_benchmarks.inspect
    @latency_benchmarks.inject(0) { |memo, obj| memo += obj[:latency] } / @latency_benchmarks.length
  end


  def benchmark_reliability

  end

  def benchmark_speed

  end  
  
end