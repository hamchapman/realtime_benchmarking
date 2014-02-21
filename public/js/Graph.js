(function() {
  
  fb_service = new FirebaseService('/analysis', "");
  fb_service.send({message: "hello firebase", time: new Date()});

  pn_service = new PubnubService("pubnubChannel", "");
  setTimeout(pn_service.send({message: "hello pubnub", time: new Date()}), 1000);
  // pn_service.send({message: "hello pubnub", time: new Date()});

  rtc_service = new RealtimeCoService('realtimeco_channel', "");
  setTimeout(function() {
    rtc_service.send({message: "hello realtimeco", time: new Date()})
  }, 2000);
  // rtc_service.send({message: "hello realtimeco", time: new Date()});

  pu_service = new PusherService('private-test-channel', "");
  setTimeout(function() {
    pu_service.send({message: "hello pusher", time: new Date()});
  }, 1000);

  gi_service = new GoInstantService("https://goinstant.net/cd2b44835134/analysis", "");
  setTimeout(function() {
    gi_service.send({message: "hello goinstant", time: new Date()});
  }, 3000);


  nv.addGraph(function() {
    var chart = nv.models.lineChart()
                  .margin({left: 100})  //Adjust chart margins to give the x-axis some breathing room.
                  .useInteractiveGuideline(true)  //We want nice looking tooltips and a guideline!
                  .transitionDuration(350)  //how fast do you want the lines to transition?
                  .showLegend(true)       //Show the legend, allowing users to turn on/off line series.
                  .showYAxis(true)        //Show the y-axis
                  .showXAxis(true)        //Show the x-axis
    ;
   
    chart.xAxis     //Chart x-axis settings
        .axisLabel('Time (ms)')
        .tickFormat(d3.format(',r'));
   
    chart.yAxis     //Chart y-axis settings
        .axisLabel('Voltage (v)')
        .tickFormat(d3.format('.02f'));
   
    /* Done setting the chart up? Time to render it!*/
    var myData = sinAndCos();   //You need data...
   
    d3.select('#chart svg')    //Select the <svg> element you want to render the chart in.   
        .datum(myData)         //Populate the <svg> element with chart data...
        .call(chart);          //Finally, render the chart!
   
    //Update the chart when window resizes.
    nv.utils.windowResize(function() { chart.update() });
    return chart;
  });

  function sinAndCos() {
    var sin = [],sin2 = [],
        cos = [];
   
    //Data is represented as an array of {x,y} pairs.
    for (var i = 0; i < 100; i++) {
      sin.push({x: i, y: Math.sin(i/10)});
      sin2.push({x: i, y: Math.sin(i/10) *0.25 + 0.5});
      cos.push({x: i, y: .5 * Math.cos(i/10)});
    }
   
    //Line chart data should be sent as an array of series objects.
    return [
      {
        values: sin,      //values - represents the array of {x,y} data points
        key: 'Sine Wave', //key  - the name of the series.
        color: '#ff7f0e'  //color - optional: choose your own line color.
      },
      {
        values: cos,
        key: 'Cosine Wave',
        color: '#2ca02c'
      },
      {
        values: sin2,
        key: 'Another sine wave',
        color: '#7777ff',
        area: true      //area - set to true if you want this line to turn into a filled area chart.
      }
    ];
  }

})();