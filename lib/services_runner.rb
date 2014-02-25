require_relative 'pusher'
require_relative 'pubnub'
require_relative 'realtime_co'

class ServicesRunner

  def initialize channel
    @services = []
    initialize_services channel
  end

  def initialize_services channel
    @pusher = PusherBenchmarker.new channel
    @pubnub = PubnubBenchmarker.new channel
    sleep 2
    @realtime_co = RealtimeCoBenchmarker.new channel
    @services += [@pusher, @pubnub, @realtime_co]
    puts @services.inspect
  end

  def benchmark_latencies 
    puts @services.inspect
    @services.each { |service| service.benchmark_latency }
    sleep 2
  end

  def benchmark_reliabilities
    puts @services.inspect
    @services.each { |service| service.benchmark_reliability }
    sleep 2
  end

  def benchmark_speeds
    @services.each { |service| service.benchamark_speed } 
  end

  def run_benchmarks
    benchmark_latencies 
    benchmark_reliabilities
    # benchmark_speeds 
  end

  def reset_benchmarkers
    @services.each { |service| service = nil }
  end

end