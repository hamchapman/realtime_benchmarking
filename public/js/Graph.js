$(document).ready(function() {
  var dateFormatIn =  d3.time.format.utc('%Y-%m-%d %H:%M:%S UTC');
  var dateFormatOut =  d3.time.format.utc('%d-%m-%Y %H:%M:%S');

  $(".update-graph-button").on( "click", function() {
    var time_data = $(".update-graph-text").val();
    $(".current-timeframe").attr("data-timeframe", time_data);
    $.ajax({
      type: 'POST',
      url: '/new_latency_data',
      data: { since: time_data },
      success: function (response) { 
        updateRubyGraph(response);
      }
    });

    $.ajax({
      type: 'POST',
      url: '/new_js_latency_data',
      data: { since: time_data },
      success: function (response) { 
        updateJSGraph(response);
      }
    });      
    
    $.ajax({
      type: 'POST',
      url: '/new_reliability_data',
      data: { since: time_data },
      success: function (response) { 
        updateReliabilities(response);
      }
    });
  });

  // Setting up Pusher for realtime updates of the graphs and reliabilities
  var pusher = new Pusher( 'a8536d1bddd6f5951242' );
  var mongoUpdateChannel = pusher.subscribe( 'mongo' );

  mongoUpdateChannel.bind( 'reliabilities-update', function( message ) {
    var current_timeframe = $(".current-timeframe").attr("data-timeframe");
    $.ajax({
      type: 'POST',
      url: '/new_reliability_data',
      data: { since: current_timeframe },
      success: function (response) { 
        updateReliabilities(response);
      }
    });      
  });


  mongoUpdateChannel.bind( 'latencies-update', function( message ) {
    var current_timeframe = $(".current-timeframe").attr("data-timeframe");
    $.ajax({
      type: 'POST',
      url: '/new_latency_data',
      data: { since: current_timeframe },
      success: function (response) { 
        updateRubyGraph(response);
      }
    });      
  });

  mongoUpdateChannel.bind( 'js-latencies-update', function( message ) {
    var current_timeframe = $(".current-timeframe").attr("data-timeframe");
    $.ajax({
      type: 'POST',
      url: '/new_js_latency_data',
      data: { since: current_timeframe },
      success: function (response) { 
        updateJSGraph(response);
      }
    });      
  });
  
  function updateRubyGraph(response) {
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

  function updateReliabilities(response) {
    var updatedData = response;

    var pusherReliability = JSON.parse(updatedData[0]);
    var pubnubReliability = JSON.parse(updatedData[1]);
    var realtimecoReliability = JSON.parse(updatedData[2]);

    $(".pusher-reliability-score").text(pusherReliability["reliability"] + "%");
    $(".pubnub-reliability-score").text(pubnubReliability["reliability"] + "%");
    $(".realtimeco-reliability-score").text(realtimecoReliability["reliability"] + "%");
  };

  function updateJSGraph (response) {
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

});