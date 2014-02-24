require_relative 'ortc'

class RealtimeCoBenchmarker

  attr_reader :subscribed

  def initialize channel
    @channel = channel
    setup
    @connected = false
    @subscribed = false
    
    @client.on_connected  do |sender|
      @connected = true
      subscribe @channel
    end


    @client.on_subscribed do |sender, channel|
      puts "I've set subscribed true"
      @subscribed = true
    end

    @client.on_unsubscribed do |sender, channel|
      disconnect
    end
  end

  def setup
    @client = ORTC::OrtcClient.new
    @client.cluster_url = 'http://ortc-developers.realtime.co/server/2.1'
    puts "I'm setting up"
  end

  def connect
    puts "I'm connecting"
    @client.connect 'BNrppn', 'NO_AUTH_NEEDED'
    puts @client.is_connected
  end

  def send message
    puts @client.is_connected
    puts "I'm sending"
    @client.send(@channel, message.to_json)
  end

  def subscribe
    puts "I'm subscribing"
    @client.subscribe(@channel, true) do |sender, channel, message| 
      puts "Message received on (#{channel}): #{message}" 
    end
  end

  def unsubscribe
    @client.unsubscribe(@channel)
  end

  def disconnect
    @client.disconnect
  end

  def benchmark_latency

  end

  def benchmark_reliability

  end

  def benchmark_speed

  end

end