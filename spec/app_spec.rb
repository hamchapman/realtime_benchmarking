require_relative './spec_helper'

describe 'Benchmark Analysis App' do
  time = Chronic.parse("yesterday 10am")

  before :each do
      $latencies_coll.insert( { service: "pusher", time: time, latency: 20 } )
      $latencies_coll.insert( { service: "pusher", time: time + 3600, latency: 200 } )
      $latencies_coll.insert( { service: "pusher", time: time + 36000, latency: 50 } )
      $latencies_coll.insert( { service: "pubnub", time: time, latency: 200 } )
      $latencies_coll.insert( { service: "pubnub", time: time + 3600, latency: 300 } )
      $latencies_coll.insert( { service: "pubnub", time: time + 36000, latency: 150 } )

      $reliabilities_coll.insert( { service: "pusher", time: time, reliability: 100 } )
      $reliabilities_coll.insert( { service: "pusher", time: time + 36000, reliability: 50 } )

      $js_latencies_coll.insert( { service: "pusher", time: time, latency: 350 } )
      $js_latencies_coll.insert( { service: "pusher", time: time + 3600, latency: 150 } )
      $js_latencies_coll.insert( { service: "pusher", time: time + 36000, latency: 250 } )
      $js_latencies_coll.insert( { service: "pubnub", time: time, latency: 100 } )
      $js_latencies_coll.insert( { service: "pubnub", time: time + 3600, latency: 200 } )
      $js_latencies_coll.insert( { service: "pubnub", time: time + 36000, latency: 300 } )
    end
  
  context 'does basic things like' do
    
    it 'shows two graphs on the homepage', js: true do
      visit '/'
      expect(page).to have_css('#chart_latency')
      expect(page).to have_css('#chart_js_latency')
    end

    it 'shows the home page', js: true do
      get '/'
      expect(last_response).to be_ok
      sleep 0.5
      expect(page).to have_content "Realtime Benchmarks"
    end

    it 'shows the ruby latency graph x-axis ranges/scales correctly', js: true do
      visit '/'
      sleep 0.5
      expect(page.first("#chart_latency .nv-x .nv-axisMaxMin text").text).to eq time.strftime("%d-%m-%Y %H:%M:%S")
      expect(page.all("#chart_latency .nv-x .nv-axisMaxMin text")[1].text).to eq (time + 36000).strftime("%d-%m-%Y %H:%M:%S")
    end

    it 'shows the ruby latency graph y-axis ranges/scales correctly', js: true do
      visit '/'
      sleep 0.5
      expect(page.first("#chart_latency .nv-y .nv-axisMaxMin text").text).to eq "20"
      expect(page.all("#chart_latency .nv-y .nv-axisMaxMin text")[1].text).to eq "300"
    end

    it 'shows the javascript latency graph x-axis ranges/scales correctly', js: true do
      visit '/'
      sleep 0.5
      expect(page.first("#chart_js_latency .nv-x .nv-axisMaxMin text").text).to eq time.strftime("%d-%m-%Y %H:%M:%S")
      expect(page.all("#chart_js_latency .nv-x .nv-axisMaxMin text")[1].text).to eq (time + 36000).strftime("%d-%m-%Y %H:%M:%S")
    end

    it 'shows the javascript latency graph y-axis ranges/scales correctly', js: true do
      visit '/'
      sleep 0.5
      expect(page.first("#chart_js_latency .nv-y .nv-axisMaxMin text").text).to eq "0"
      expect(page.all("#chart_js_latency .nv-y .nv-axisMaxMin text")[1].text).to eq "350"
    end

    it 'shows the correct reliability score', js: true do
      visit '/' 
      expect(page.find('.reliabilities .pusher-reliability-score').text).to eq "75%"
    end
  end

  context 'Updating the graphs and reliabilities in realtime' do    
    it 'the ruby latency graph updates', js: true do
      visit '/'
      expect(page.first("#chart_latency .nv-y .nv-axisMaxMin text").text).to eq "20"
      expect(page.all("#chart_latency .nv-y .nv-axisMaxMin text")[1].text).to eq "300"
      $latencies_coll.insert( { service: "pusher", time: time + 39600, latency: 10 } )
      $latencies_coll.insert( { service: "pubnub", time: time + 39600, latency: 400 } )
      Pusher.trigger('mongo', 'latencies-update', 'Mongo updated')
      expect(page.first("#chart_latency .nv-y .nv-axisMaxMin text").text).to eq "10"
      expect(page.all("#chart_latency .nv-y .nv-axisMaxMin text")[1].text).to eq "400"
    end

    it 'the javascript latency graph updates', js: true do
      visit '/'
      expect(page.first("#chart_js_latency .nv-y .nv-axisMaxMin text").text).to eq "0"
      expect(page.all("#chart_js_latency .nv-y .nv-axisMaxMin text")[1].text).to eq "350"
      $js_latencies_coll.insert( { service: "pusher", time: time + 39600, latency: 10 } )
      $js_latencies_coll.insert( { service: "pubnub", time: time + 39600, latency: 400 } )
      Pusher.trigger('mongo', 'js-latencies-update', 'Mongo updated')
      expect(page.first("#chart_js_latency .nv-y .nv-axisMaxMin text").text).to eq "0"
      expect(page.all("#chart_js_latency .nv-y .nv-axisMaxMin text")[1].text).to eq "400"
    end

    it 'the javascript latency graph updates when a post request is made to /test', js: true do
      visit '/'
      expect(page.first("#chart_js_latency .nv-y .nv-axisMaxMin text").text).to eq "0"
      expect(page.all("#chart_js_latency .nv-y .nv-axisMaxMin text")[1].text).to eq "350"
      payload = {"latencies"=>{"pubnub"=>"70", "pusher"=>"400"}}
      post '/test', payload
      sleep 0.5
      expect(page.first("#chart_js_latency .nv-y .nv-axisMaxMin text").text).to eq "0"
      expect(page.all("#chart_js_latency .nv-y .nv-axisMaxMin text")[1].text).to eq "400"
    end

    it 'the reliability score updates', js: true do
      visit '/' 
      expect(page.find('.reliabilities .pusher-reliability-score').text).to eq "75%"
      $reliabilities_coll.insert( { service: "pusher", time: time + 39600, reliability: 90 } )
      Pusher.trigger('mongo', 'reliabilities-update', 'Mongo updated')
      sleep 0.5
      expect(page.find('.reliabilities .pusher-reliability-score').text).to eq "80%"
    end

  end

  context 'Updating the graphs and reliabilities when a "show data sine" time is specified' do
    it 'the ruby latency graph updates when a time is specified in the "view data since" input', js: true do
      visit '/'
      expect(page.first("#chart_latency .nv-y .nv-axisMaxMin text").text).to eq "20"
      expect(page.all("#chart_latency .nv-y .nv-axisMaxMin text")[1].text).to eq "300"
      fill_in 'time', with: 'yesterday 10:30am'
      click_button 'Update'
      sleep 0.5
      expect(page.first("#chart_latency .nv-y .nv-axisMaxMin text").text).to eq "50"
      expect(page.all("#chart_latency .nv-y .nv-axisMaxMin text")[1].text).to eq "300"
    end

    it 'the javascript latency graph updates when a time is specified in the "view data since" input', js: true do
      visit '/'
      expect(page.first("#chart_js_latency .nv-y .nv-axisMaxMin text").text).to eq "0"
      expect(page.all("#chart_js_latency .nv-y .nv-axisMaxMin text")[1].text).to eq "350"
      fill_in 'time', with: 'yesterday 10:30am'
      click_button 'Update'
      sleep 0.5
      expect(page.first("#chart_js_latency .nv-y .nv-axisMaxMin text").text).to eq "0"
      expect(page.all("#chart_js_latency .nv-y .nv-axisMaxMin text")[1].text).to eq "300"
    end

    it 'the reliability score updates', js: true do
      visit '/' 
      expect(page.find('.reliabilities .pusher-reliability-score').text).to eq "75%"
      fill_in 'time', with: 'yesterday 10:30am'
      click_button 'Update'
      sleep 0.5
      expect(page.find('.reliabilities .pusher-reliability-score').text).to eq "50%"
    end
  end

end