require 'pusher_benchmarker'
require 'pubnub_benchmarker'
require 'realtime_co_benchmarker'

class ServicesRunner

  def initialize channel
    @services = []
    initialize_services channel
  end

  def initialize_services channel
    @pusher = Benchmarker::PusherBenchmarker.new channel
    @pubnub = Benchmarker::PubnubBenchmarker.new channel
    sleep 2
    @realtime_co = Benchmarker::RealtimeCoBenchmarker.new channel
    @services += [@pusher, @pubnub, @realtime_co]
  end

  def benchmark_latencies 
    @services.each do |service| 
      service.benchmark_latency
      sleep 2
    end
    sleep 3
  end

  def benchmark_reliabilities
    @services.each do |service| 
      service.benchmark_reliability
      sleep 2
    end
    sleep 3
  end

  # def benchmark_speeds
  #   @services -= [@pubnub]
  #   @services.each do |service| 
  #     service.benchmark_speed
  #     sleep 2
  #   end
  #   sleep 3
  # end

  # Can't benchmark the speeds at the moment because there's a
  # problem with threads being created and then not terminated
  # if the client fails to connect then it can't be disconnected
  # leaving it in a position where it isn't connected but still
  # is taking up a thread and can't be disconnected

  def run_benchmarks
    benchmark_latencies 
    benchmark_reliabilities
    # benchmark_speeds
    reset_benchmarkers
  end

  def reset_benchmarkers
    @services.each { |service| service = nil }
  end

end