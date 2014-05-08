require 'pusher'
require 'pusher-client'
require 'json'

module Benchmarker
  class PusherBenchmarker

    attr_reader :ready

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
        $reliabilities_coll.insert( { service: "pusher", time: Time.now, reliability: reliability } )
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
        @client.bind('pusher_internal:subscription_succeeded') do |data|
          end_time = Time.now
          startup_times << (end_time - start_time) * 1000
        end
        connect
        subscribe
        sleep 1.5
      end
      $speeds_coll.insert( { service: "pusher", time: Time.now, speed: average_speed(startup_times) } )
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