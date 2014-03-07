$(document).ready(function() {
  var dateFormatIn =  d3.time.format.utc('%Y-%m-%d %H:%M:%S UTC');
  var dateFormatOut =  d3.time.format.utc('%d-%m-%Y %H:%M:%S');

  var current_timeframe = $(".current-timeframe").attr("data-timeframe");
  loadPageData(current_timeframe);

  $(".update-graph-button").on( "click", function() {
    var time_data = $(".update-graph-text").val();
    $(".current-timeframe").attr("data-timeframe", time_data);
    loadPageData(time_data);
  });

  // Setting up Pusher for realtime updates of the graphs and reliabilities
  var pusher = new Pusher( 'a8536d1bddd6f5951242' );
  var mongoUpdateChannel = pusher.subscribe( 'mongo' );

  mongoUpdateChannel.bind( 'reliabilities-update', function( message ) {
    var current_timeframe = $(".current-timeframe").attr("data-timeframe");
    loadRubyReliabilities(current_timeframe); 
  });

  mongoUpdateChannel.bind( 'latencies-update', function( message ) {
    var current_timeframe = $(".current-timeframe").attr("data-timeframe");
    loadRubyLatencyGraph(current_timeframe);
  });

  mongoUpdateChannel.bind( 'js-latencies-update', function( message ) {
    var current_timeframe = $(".current-timeframe").attr("data-timeframe");
    loadJSLatencyGraph(current_timeframe);
  });

  // mongoUpdateChannel.bind( 'speeds-update', function( message ) {
  //   var current_timeframe = $(".current-timeframe").attr("data-timeframe");
  //   loadRubySpeedGraph(current_timeframe);
  // });
  
  function updateRubyLatencyGraph (response) {
    var updatedData = response;
    var serviceData = [];

    updatedData.forEach(function(individualServiceData) {
      serviceData.push(JSON.parse(individualServiceData));
    });
    
    nv.addGraph(function() {
      var chart = nv.models.lineChart()
        .x(function(d){return dateFormatIn.parse(d.x);})
        .margin({left: 100, bottom: 100})  
        .useInteractiveGuideline(true)  
        .transitionDuration(350)  
        .showLegend(true)       
        .showYAxis(true)        
        .showXAxis(true);
      
      chart.xAxis 
        .rotateLabels(-45)
        .tickFormat(function(d) { return dateFormatOut(new Date(d)) });
       
      chart.yAxis
        .axisLabel('Latency (ms)')
        .tickFormat(d3.format('.0f'));

      d3.select('#chart_latency svg')    
        .datum(serviceData)
        .call(chart);

      nv.utils.windowResize(function() { chart.update() });
      return chart;
    });
  };

  function updateReliabilities (response) {
    var updatedData = response;

    var pusherReliability = JSON.parse(updatedData[0]);
    var pubnubReliability = JSON.parse(updatedData[1]);
    var realtimecoReliability = JSON.parse(updatedData[2]);

    $(".pusher-reliability-score").text(pusherReliability["reliability"] + "%");
    $(".pubnub-reliability-score").text(pubnubReliability["reliability"] + "%");
    $(".realtimeco-reliability-score").text(realtimecoReliability["reliability"] + "%");
  };

  function updateJSLatencyGraph (response) {
    var updatedData = response;
    var serviceWideMaxY = 0;
    var serviceData = [];

    // Calculate maximum y value in JS latency data
    updatedData.forEach(function(individualServiceData) {
      serviceData.push(JSON.parse(individualServiceData));
      var dataPoints = JSON.parse(individualServiceData)["values"];
      dataPoints.forEach(function(point) {
      var yValue = point["y"];
        if (parseFloat(yValue) > serviceWideMaxY) {
          serviceWideMaxY = parseFloat(yValue);
        }
      })
    });
      
    nv.addGraph(function() {
      var chart = nv.models.lineChart()
        .x(function(d){return dateFormatIn.parse(d.x);})
        .margin({left: 100, bottom: 100})  
        .useInteractiveGuideline(true)  
        .transitionDuration(350)  
        .showLegend(true)       
        .showYAxis(true)        
        .showXAxis(true)
        .forceY([0, serviceWideMaxY]);
      
      chart.xAxis 
        .rotateLabels(-45)
        .tickFormat(function(d) { return dateFormatOut(new Date(d)) });
       
      chart.yAxis
        .axisLabel('Latency (ms)')
        .tickFormat(d3.format('.0f'));

      d3.select('#chart_js_latency svg')    
        .datum(serviceData)
        .call(chart);

      nv.utils.windowResize(function() { chart.update() });
      return chart;
    });
  };

  function updateRubySpeedGraph (response) {
    var updatedData = response;
    var serviceData = [];

    updatedData.forEach(function(individualServiceData) {
      serviceData.push(JSON.parse(individualServiceData));
    });
    
    nv.addGraph(function() {
      var chart = nv.models.lineChart()
        .x(function(d){return dateFormatIn.parse(d.x);})
        .margin({left: 100, bottom: 100})  
        .useInteractiveGuideline(true)  
        .transitionDuration(350)  
        .showLegend(true)       
        .showYAxis(true)        
        .showXAxis(true);
      
      chart.xAxis 
        .rotateLabels(-45)
        .tickFormat(function(d) { return dateFormatOut(new Date(d)) });
       
      chart.yAxis
        .axisLabel('Time (ms)')
        .tickFormat(d3.format('.0f'));

      d3.select('#chart_speed svg')    
        .datum(serviceData)
        .call(chart);

      nv.utils.windowResize(function() { chart.update() });
      return chart;
    });
  };

  function loadPageData (current_timeframe) {
    loadRubyLatencyGraph(current_timeframe);
    loadJSLatencyGraph(current_timeframe);
    loadRubyReliabilities(current_timeframe);
    // loadRubySpeedGraph(current_timeframe);
  };

  function loadRubyLatencyGraph (current_timeframe) {
    $.ajax({
      type: 'POST',
      url: '/new_latency_data',
      data: { since: current_timeframe },
      success: function (response) { 
        updateRubyLatencyGraph(response);
      }
    });
  };

  function loadJSLatencyGraph (current_timeframe) {
    $.ajax({
      type: 'POST',
      url: '/new_js_latency_data',
      data: { since: current_timeframe },
      success: function (response) { 
        updateJSLatencyGraph(response);
      }
    });
  };

  function loadRubySpeedGraph (current_timeframe) {
    $.ajax({
      type: 'POST',
      url: '/new_speed_data',
      data: { since: current_timeframe },
      success: function (response) { 
        updateRubySpeedGraph(response);
      }
    });
  };

  function loadRubyReliabilities (current_timeframe) {
    $.ajax({
      type: 'POST',
      url: '/new_reliability_data',
      data: { since: current_timeframe },
      success: function (response) { 
        updateReliabilities(response);
      }
    });
  };

});