require 'pubnub'

class PubnubBenchmarker

  def initialize 
    
  end

  def self.connect
    pubnub = Pubnub.new(
        :subscribe_key    => 'sub-c-170fcba8-9973-11e3-8d39-02ee2ddab7fe',
        :publish_key      => 'pub-c-28b03a80-5f93-4d3c-a431-e08e20e7e446',
        :origin           => origin,
        :uuid              => "225388",
        :error_callback   => lambda { |msg|
          puts "SOMETHING TERRIBLE HAPPENED HERE: #{msg.inspect}"
        },
        :connect_callback => lambda { |msg|
          puts "CONNECTED: #{msg.inspect}"
        }
    )
  end

  # @my_callback = lambda { |envelope| puts(envelope.msg) }

  def self.send message, channel
    pubnub.publish(
        :channel  => channel,
        :message  => {time: Time.now, message: message},
        :callback => @my_callback
    )
  end

  def self.subscribe channel
    pubnub.subscribe(
        :channel  => channel,
        :callback => @my_callback
    )
  end
end