require 'firebase'

class FirebaseBenchmarker

  def initialize 
    
  end

  def self.connect
    base_uri = 'https://analysis.firebaseio.com/'
    firebase = Firebase.new(base_uri) 
  end

  def self.send message, firebase
    firebase.push(path, data, query_options)
  end

  def self.subscribe channel
    
  end
end