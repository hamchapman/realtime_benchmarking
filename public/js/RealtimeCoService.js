// (function() {
  
//   loadOrtcFactory(IbtRealTimeSJType, function (factory, error) {
  
//     if (error != null) {
//       alert("Factory error: " + error.message);
//     } 

//     else {
    
//       if (factory != null) {
//         var client = factory.createClient();
//         client.setClusterUrl('http://ortc-developers.realtime.co/server/2.1/');
              
//         client.onConnected = function (theClient) {
                  
//         theClient.subscribe('myChannel', true,
//                 function (theClient, channel, msg) {
//                   console.log("Received message:", msg);                       
//                   theClient.unsubscribe(channel);
//                 });                                
//         };
   
//         client.onSubscribed = function (theClient, channel) {
//           theClient.send(channel, 'Hello World');
//         };
             
//         client.connect('BNrppn', 'NOT_NEEDED_BECAUSE_NO_AUTHENTICATION_TURNED_ON');
//       }
//     }
//   });

// })();

function RealtimeCoService() {
  BenchmarkService.apply( this, arguments );
    
  this.name = 'RealtimeCo';
    
  var self = this;

  loadOrtcFactory(IbtRealTimeSJType, function (factory, error) {
    if (error != null) {
    } else {
      self._init(factory);
    }
  });
}
RealtimeCoService.prototype = new BenchmarkService;

RealtimeCoService.prototype._init = function( ortcFactory ) {
  var self = this;

  console.log("hello");

  this._client = ortcFactory.createClient();
  var url = 'http://ortc-developers.realtime.co/server/2.1/'
  var isCluster = true;

  console.log(this._client);

  this._client.setId('LatencyClient');
  this._client.setConnectionTimeout(15000);

  if (isCluster) {
    this._client.setClusterUrl(url);
  } else {
    this._client.setUrl(url);
  }
 
  this._client.onConnected = function () {
    self._client.subscribe(self._channelName, true, function( ortc, channel, message ) {
      message = JSON.parse(message);
      console.log(message);
      // self._onMessage( message );
    });

    // self._onReady();
  };

  this._client.onException = function (ortc, exception) {
    var msg = exception;
    if(exception == 'Invalid connection.') {
      msg += ' Please reload the page to authenticate again';
    }
    self._log('Error: ' + msg);   
  };

  var appKey = 'BNrppn'; 
  var authenticationToken = 'NOT_USED_BECAUSE_AUTH_IS_SET_OFF_IN_THE_DASHBOARD';
  this._client.connect(appKey, authenticationToken);
};

RealtimeCoService.prototype.send = function( data ) {
   this._client.send( this._channelName, JSON.stringify( data ) );
};

RealtimeCoService.prototype.disconnect = function() {
  this._client.disconnect();
};