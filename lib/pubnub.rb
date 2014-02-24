require 'pubnub'
require 'pry'

class PubnubBenchmarker

  attr_reader :ready

  def initialize channel
    @channel = channel
    @ready = false
    @latency_benchmarks = []
    connect
    subscribe
  end

  def connect
    puts "Connecting"
    @client = Pubnub.new(
        :subscribe_key    => 'sub-c-170fcba8-9973-11e3-8d39-02ee2ddab7fe',
        :publish_key      => 'pub-c-28b03a80-5f93-4d3c-a431-e08e20e7e446',
        :error_callback   => lambda { |msg|
          puts "SOMETHING TERRIBLE HAPPENED HERE: #{msg.inspect}"
        }, 
        :connect_callback => lambda { |msg|
          @ready = true
        }
    )
  end

  def send message
    @client.publish({
        :channel  => @channel,
        :message  => message,
        :callback => lambda { |msg| }
    })
  end

  def subscribe
    puts "Subscribing"
    @client.subscribe(
        :channel  => @channel,
        :callback => lambda { |data|
          sent = (Time.parse(data.message["time"])).to_f
          received = Time.now.to_f
          latency = (received - sent) * 1000
          puts data.message.inspect
          puts latency
          @latency_benchmarks << { service: "pubnub", time: Time.now, latency: latency }
       }
    )
  end

  def unsubscribe
    @client.unsubscribe( :channel  => @channel ) { |data| puts data.msg }
  end

  def benchmark_latency
    while (!ready)
      sleep(1)
    end
    (1..20).each do |num|
      send({time: Time.now, id: num})
    end
    sleep 2.0
    $latencies_coll.insert( { service: "pubnub", time: Time.now, latency: average_latency } )
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