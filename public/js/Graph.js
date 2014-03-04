(function() {

  $(".update-graph-button").on( "click", function() {
    var time_data = $(".update-graph-text").val();
    $(".current-timeframe").attr("data-timeframe", time_data);
    $.ajax({
      type: 'POST',
      url: '/new_latency_data',
      data: { since: time_data },
      success: function (response) {
                console.log(response);
                var updatedData = response;
                
                nv.addGraph(function() {
                  var chart = nv.models.lineChart()
                    .margin({left: 100, bottom: 100})  
                    .useInteractiveGuideline(true)  
                    .transitionDuration(350)  
                    .showLegend(true)       
                    .showYAxis(true)        
                    .showXAxis(true);
                  
                  chart.xAxis 
                    .rotateLabels(-45)
                    .tickFormat(function(d) { return d3.time.format('%d-%m-%Y %H:%M:%S')(new Date(d)) });
                   
                  chart.yAxis
                    .axisLabel('Latency (ms)')
                    .tickFormat(d3.format('.0f'));


                  // var pusherData = JSON.parse(updatedData[0]);
                  // var pubnubData = JSON.parse(updatedData[1]);
                  // var realtimecoData = JSON.parse(updatedData[2]);

                  // pusherData["values"].forEach(function(hash) {
                  //   hash["x"] = new Date(hash["x"]);
                  // });

                  // pubnubData["values"].forEach(function(hash) {
                  //   hash["x"] = new Date(hash["x"]);
                  // });

                  // realtimecoData["values"].forEach(function(hash) {
                  //   hash["x"] = new Date(hash["x"]);
                  // });

                  // var serviceData = [pusherData, pubnubData, realtimecoData];
                  
                  var serviceData = [JSON.parse(updatedData[0], JSON.parse(updatedData[0]), JSON.parse(updatedData[2])];
                  
                  // Make the dates easy for d3 to work with
                  serviceData.forEach(function(individualServiceData) {
                    individualServiceData["values"].forEach(function(hash) {
                      hash["x"] = new Date(hash["x"]);
                    });
                  });

                  d3.select('#chart_latency svg')    
                    .datum(serviceData)
                    .call(chart);

                  nv.utils.windowResize(function() { chart.update() });
                  return chart;
                });
      }
    });

    $.ajax({
      type: 'POST',
      url: '/new_js_latency_data',
      data: { since: time_data },
      success: function (response) {
                console.log(response);
                var updatedData = response;
                
                nv.addGraph(function() {
                  var chart = nv.models.lineChart()
                    .margin({left: 100, bottom: 100})  
                    .useInteractiveGuideline(true)  
                    .transitionDuration(350)  
                    .showLegend(true)       
                    .showYAxis(true)        
                    .showXAxis(true)
                    .forceY(0);
                  
                  chart.xAxis 
                    .rotateLabels(-45)
                    .tickFormat(function(d) { return d3.time.format('%d-%m-%Y %H:%M:%S')(new Date(d)) });
                   
                  chart.yAxis
                    .axisLabel('Latency (ms)')
                    .tickFormat(d3.format('.0f'));

                  var serviceData = [JSON.parse(updatedData[0], JSON.parse(updatedData[0]), JSON.parse(updatedData[2]), JSON.parse(updatedData[3]), JSON.parse(updatedData[4]];
                  
                  // Make the dates easy for d3 to work with
                  serviceData.forEach(function(individualServiceData) {
                    individualServiceData["values"].forEach(function(hash) {
                      hash["x"] = new Date(hash["x"]);
                    });
                  });

                  d3.select('#chart_js_latency svg')    
                    .datum(serviceData)
                    .call(chart);

                  nv.utils.windowResize(function() { chart.update() });
                  return chart;
                });
      }
    });      
    
    $.ajax({
      type: 'POST',
      url: '/new_reliability_data',
      data: { since: time_data },
      success: function (response) {
        var updatedData = response;

        var pusherReliability = JSON.parse(updatedData[0]);
        var pubnubReliability = JSON.parse(updatedData[1]);
        var realtimecoReliability = JSON.parse(updatedData[2]);

        $(".pusher-reliability-score").text(pusherReliability["reliability"] + "%")
        $(".pubnub-reliability-score").text(pubnubReliability["reliability"] + "%")
        $(".realtimeco-reliability-score").text(realtimecoReliability["reliability"] + "%")
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
        var updatedData = response;

        var pusherReliability = JSON.parse(updatedData[0]);
        var pubnubReliability = JSON.parse(updatedData[1]);
        var realtimecoReliability = JSON.parse(updatedData[2]);

        $(".pusher-reliability-score").text(pusherReliability["reliability"] + "%")
        $(".pubnub-reliability-score").text(pubnubReliability["reliability"] + "%")
        $(".realtimeco-reliability-score").text(realtimecoReliability["reliability"] + "%")
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
                console.log(response);
                var updatedData = response;
                
                nv.addGraph(function() {
                  var chart = nv.models.lineChart()
                    .margin({left: 100, bottom: 100})  
                    .useInteractiveGuideline(true)  
                    .transitionDuration(350)  
                    .showLegend(true)       
                    .showYAxis(true)        
                    .showXAxis(true);
                  
                  chart.xAxis 
                    .rotateLabels(-45)
                    .tickFormat(function(d) { return d3.time.format('%d-%m-%Y %H:%M:%S')(new Date(d)) });
                   
                  chart.yAxis
                    .axisLabel('Latency (ms)')
                    .tickFormat(d3.format('.0f'));

                  var serviceData = [JSON.parse(updatedData[0], JSON.parse(updatedData[0]), JSON.parse(updatedData[2])];
                  
                  // Make the dates easy for d3 to work with
                  serviceData.forEach(function(individualServiceData) {
                    individualServiceData["values"].forEach(function(hash) {
                      hash["x"] = new Date(hash["x"]);
                    });
                  });

                  d3.select('#chart_latency svg')    
                    .datum(serviceData)
                    .call(chart);

                  nv.utils.windowResize(function() { chart.update() });
                  return chart;
                });
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
                console.log(response);
                var updatedData = response;
                
                console.log(updatedData);                    
                var serviceWideMaxY = 0;

                // Calculate maximum y value in JS latency data
                updatedData.forEach(function(individualServiceData) {
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
                    .margin({left: 100, bottom: 100})  
                    .useInteractiveGuideline(true)  
                    .transitionDuration(350)  
                    .showLegend(true)       
                    .showYAxis(true)        
                    .showXAxis(true)
                    .forceY([0, serviceWideMaxY]);
                  
                  chart.xAxis 
                    .rotateLabels(-45)
                    .tickFormat(function(d) { return d3.time.format('%d-%m-%Y %H:%M:%S')(new Date(d)) });
                   
                  chart.yAxis
                    .axisLabel('Latency (ms)')
                    .tickFormat(d3.format('.0f'));

                  var serviceData = [JSON.parse(updatedData[0], JSON.parse(updatedData[0]), JSON.parse(updatedData[2]), JSON.parse(updatedData[3]), JSON.parse(updatedData[4]];
                  
                  // Make the dates easy for d3 to work with
                  serviceData.forEach(function(individualServiceData) {
                    individualServiceData["values"].forEach(function(hash) {
                      hash["x"] = new Date(hash["x"]);
                    });
                  });

                  // var pusherData = JSON.parse(updatedData[0]);
                  // var pubnubData = JSON.parse(updatedData[1]);
                  // var realtimecoData = JSON.parse(updatedData[2]);
                  // var firebaseData = JSON.parse(updatedData[3]);
                  // var goinstantData = JSON.parse(updatedData[4]);


                  // // Make the dates easy for d3 to work with
                  // pusherData["values"].forEach(function(hash) {
                  //   hash["x"] = new Date(hash["x"]);
                  // });
                  // pubnubData["values"].forEach(function(hash) {
                  //   hash["x"] = new Date(hash["x"]);
                  // });
                  // realtimecoData["values"].forEach(function(hash) {
                  //   hash["x"] = new Date(hash["x"]);
                  // });
                  // firebaseData["values"].forEach(function(hash) {
                  //   hash["x"] = new Date(hash["x"]);
                  // });
                  // goinstantData["values"].forEach(function(hash) {
                  //   hash["x"] = new Date(hash["x"]);
                  // });

                  // var serviceData = [pusherData, pubnubData, realtimecoData, firebaseData, goinstantData];

                  d3.select('#chart_js_latency svg')    
                    .datum(serviceData)
                    .call(chart);

                  nv.utils.windowResize(function() { chart.update() });
                  return chart;
                });
      }
    });      
  });

})();