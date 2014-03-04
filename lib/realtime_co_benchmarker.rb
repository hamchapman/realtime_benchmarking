require_relative 'ortc'

module Benchmarker
  class RealtimeCoBenchmarker

    attr_reader :ready, :subscribed

    def initialize channel
      @channel = channel
      setup
      @benchmarks = []
      @subscribed = false
      @ready = false
      
      @client.on_connected  do |sender|
        subscribe
      end

      @client.on_subscribed do |sender, channel|
        @ready = true
      end

      @client.on_unsubscribed do |sender, channel|
        disconnect
      end

      connect
    end

    def setup
      @client = ORTC::OrtcClient.new
      @client.cluster_url = 'http://ortc-developers.realtime.co/server/2.1'
    end

    def connect
      @client.connect 'BNrppn'
    end

    def disconnect
      # @client.disconnect
    end

    def send message
      @client.send(@channel, message.to_json)
    end

    def subscribe
      @client.subscribe(@channel, true) do |sender, channel, message| 
        message = JSON.parse(message)
        sent = (Time.parse(message["time"])).to_f
        received = Time.now.to_f
        latency = (received - sent) * 1000
        # puts latency
        puts message.inspect
        @benchmarks << { service: "realtime_co", time: Time.now, latency: latency }
      end
    end

    def unsubscribe
      @client.unsubscribe(@channel)
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
      $latencies_coll.insert( { service: "realtime_co", time: Time.now, latency: average_latency } )
      Pusher.trigger('mongo', 'latencies-update', 'Mongo updated')
      puts @benchmarks.inspect
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
      $reliabilities_coll.insert( { service: "realtime_co", time: Time.now, reliability: calculate_reliability_percentage } )
      Pusher.trigger('mongo', 'reliabilities-update', 'Mongo updated')
      puts @benchmarks.inspect
      @benchmarks = []
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
      # disconnect
      @client = nil
    end

  end
end