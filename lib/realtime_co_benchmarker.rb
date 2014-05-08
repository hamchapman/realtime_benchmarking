require_relative 'ortc'

module Benchmarker
  class RealtimeCoBenchmarker

    attr_reader :ready

    def initialize channel
      @channel = channel
      setup
      @benchmarks = []
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
      @client.connect '5fgsck'
    end

    def disconnect
      @client.disconnect
    end

    def send message
      @client.send(@channel, message.to_json)
    end

    def subscribe
      @client.subscribe(@channel, true) do |sender, channel, message|
        parsed_message = JSON.parse(message)
        sent = (Time.parse(parsed_message["time"])).to_f
        received = Time.now.to_f
        latency = (received - sent) * 1000
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
      latency = average_latency
      if latency > 2000
        $latencies_coll.insert( { service: "realtime_co", time: Time.now, latency: 2000 } )
      else
        $latencies_coll.insert( { service: "realtime_co", time: Time.now, latency: latency } )
      end
      Pusher.trigger('mongo', 'latencies-update', 'Mongo updated')
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
      reliability = calculate_reliability_percentage
      if reliability <= 100
        $reliabilities_coll.insert( { service: "realtime_co", time: Time.now, reliability: reliability } )
        Pusher.trigger('mongo', 'reliabilities-update', 'Mongo updated')
      end
      @benchmarks = []
      reset_client
    end

    def calculate_reliability_percentage
      (@benchmarks.length / 20.0) * 100
    end

    def benchmark_speed
      setup
      startup_times = []
      (1..10).each do |num|
        reset_client
        end_time = 0
        setup
        start_time = Time.now
        @client.on_subscribed do |sender, channel|
          end_time = Time.now
          startup_times << (end_time - start_time) * 1000
        end
        @client.on_connected  do |sender|
          subscribe
        end
        connect
        sleep 1.5
      end
      $speeds_coll.insert( { service: "realtime_co", time: Time.now, speed: average_speed(startup_times) } )
      startup_times = []
      reset_client
      Pusher.trigger('mongo', 'speeds-update', 'Mongo updated')
    end

    def average_speed startup_times
      startup_times.inject(0, :+) / startup_times.length
    end

    def reset_client
      unsubscribe
      disconnect
      @client = nil
    end

  end
end