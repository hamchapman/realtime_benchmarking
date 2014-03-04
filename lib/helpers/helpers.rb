module ApplicationHelper

  def latency_data_for service, colour, data
    service_data = data.select { |entry| entry['service'] == service }
    service_data.each do |hash|
      hash[:x] = hash.delete "time"
      hash[:y] = hash.delete "latency"
      hash.delete "_id"
      hash.delete "service"
    end
    { values: service_data, key: service, color: colour }.to_json
  end

  def reliability_data_for service, colour, data
    service_data = data.select { |entry| entry['service'] == service }
    reliability = service_data.inject(0) { |memo, obj| memo += obj['reliability'] } / service_data.length if !service_data.empty?

    { service: service, reliability: reliability, color: colour }.to_json
  end

  def seperated_realiability_data reliability_data
    pusher_reliability = reliability_data_for 'pusher', $pusher_colour, reliability_data
    pubnub_reliability = reliability_data_for 'pubnub', $pubnub_colour, reliability_data
    realtime_co_reliability = reliability_data_for 'realtime_co', $realtime_co_colour, reliability_data
    [pusher_reliability, pubnub_reliability, realtime_co_reliability]
  end

  def separated_latency_data latency_data
    pusher_latency = latency_data_for 'pusher', $pusher_colour, latency_data
    pubnub_latency = latency_data_for 'pubnub', $pubnub_colour, latency_data
    realtime_co_latency = latency_data_for 'realtime_co', $realtime_co_colour, latency_data
    [pusher_latency, pubnub_latency, realtime_co_latency]
  end

  def separated_js_latency_data latency_data
    pusher_js_latency = latency_data_for 'pusher', $pusher_colour, latency_data
    pubnub_js_latency = latency_data_for 'pubnub', $pubnub_colour, latency_data
    realtime_co_js_latency = latency_data_for 'realtimeco', $realtime_co_colour, latency_data
    firebase_js_latency = latency_data_for 'firebase', $firebase_colour, latency_data
    goinstant_js_latency = latency_data_for 'goinstant', $goinstant_colour, latency_data
    [pusher_js_latency, pubnub_js_latency, realtime_co_js_latency, firebase_js_latency, goinstant_js_latency]
  end

  def save_latencies_to_db latencies
    latencies.each do |service, latency|
      $js_latencies_coll.insert( { service: service, time: Time.now, latency: latency } )
    end
  end

  def time_specific_data collection, since_time
    ENV['RACK_ENV'] == 'test' ? settings.mongo_db['realtime_benchmarks_test']["#{collection}"].find({ time: { "$gt" => since_time } }, sort: ["time", 1]).to_a
                              : settings.mongo_db['realtime_benchmarks']["#{collection}"].find({ time: { "$gt" => since_time } }, sort: ["time", 1]).to_a
      
  end

  def last_week_data collection
    ENV['RACK_ENV'] == 'test' ? settings.mongo_db['realtime_benchmarks_test']["#{collection}"].find({ time: { "$gt" => Time.now - 7*24*60*60 } }, sort: ["time", 1]).to_a
                              : settings.mongo_db['realtime_benchmarks']["#{collection}"].find({ time: { "$gt" => Time.now - 7*24*60*60 } }, sort: ["time", 1]).to_a
  end

end