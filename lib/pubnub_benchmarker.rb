require 'pubnub'

module Benchmarker
  class PubnubBenchmarker

    attr_reader :ready

    def initialize channel
      @channel = channel
      @ready = false
      @benchmarks = []
      connect
      subscribe
    end

    def connect
      @client = Pubnub.new(
          :subscribe_key    => 'sub-c-170fcba8-9973-11e3-8d39-02ee2ddab7fe',
          :publish_key      => 'pub-c-28b03a80-5f93-4d3c-a431-e08e20e7e446',
          :error_callback   => lambda { |msg|
          },
          :connect_callback => lambda { |msg|
            @ready = true
          }
      )
    end

    def disconnect
      @client.close_connection
    end

    def send message
      @client.publish({
          :channel  => @channel,
          :message  => message,
          :callback => lambda { |msg| }
      })
    end

    def subscribe
      @client.subscribe(
          :channel  => @channel,
          :callback => lambda { |data|
            sent = (Time.parse(data.message["time"])).to_f
            received = Time.now.to_f
            latency = (received - sent) * 1000
            @benchmarks << { service: "pubnub", time: Time.now, latency: latency }
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
        sleep 0.2
      end
      sleep 2
      latency = average_latency
      if latency > 2000
        $latencies_coll.insert( { service: "pubnub", time: Time.now, latency: 2000 } )
      else
        $latencies_coll.insert( { service: "pubnub", time: Time.now, latency: latency } )
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
      sleep 2
      reliability = calculate_reliability_percentage
      if reliability <= 100
        $reliabilities_coll.insert( { service: "pubnub", time: Time.now, reliability: reliability } )
        Pusher.trigger('mongo', 'reliabilities-update', 'Mongo updated')
      end
      @benchmarks = []
      reset_client
    end

    def calculate_reliability_percentage
      (@benchmarks.length / 20.0) * 100
    end

    def reset_client
      unsubscribe
      disconnect
      @client = nil
    end

  end
end