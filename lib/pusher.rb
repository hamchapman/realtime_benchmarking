require 'pusher'
require 'pusher-client'

class PusherBenchmarker

  def initialize 
    
  end

  def self.connect
    socket = PusherClient::Socket.new(Pusher.key)
    socket.connect(true)

    loop do
      sleep(1) # Keep your main thread running
    end
  end

  def self.subscribe channel
    socket[channel].bind('event') do |data|
      puts data
    end
  end
    
  def self.send message, channel
    Pusher.trigger(channel, 'event', {time: Time.now, message: message})
  end
end