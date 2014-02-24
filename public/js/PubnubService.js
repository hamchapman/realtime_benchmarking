function PubnubService() {
  BenchmarkService.apply( this, arguments );
  
  this.name = 'PubNub';

  this.pubnub = PUBNUB.init( {
    publish_key: 'pub-c-28b03a80-5f93-4d3c-a431-e08e20e7e446',
    subscribe_key: 'sub-c-170fcba8-9973-11e3-8d39-02ee2ddab7fe'
  } );
  
  var self = this;
  
  self.pubnub.subscribe({
    channel    : self._channelName,

    restore    : false,              // STAY CONNECTED, EVEN WHEN BROWSER IS CLOSED
                                     // OR WHEN PAGE CHANGES.

    callback   : function(message) {
      console.log(message);
      self._onMessage( message );
    },

    disconnect : function() {        // LOST CONNECTION.
      self._log(
        "Connection Lost." +
        "Will auto-reconnect when Online."
      );
    },

    reconnect  : function() {        // CONNECTION RESTORED.
      self._log("And we're Back!")
    },

    connect    : function() {
      self._onReady();
    }
  });
}
PubnubService.prototype = new BenchmarkService;

PubnubService.prototype.send = function( data ) {
  this.pubnub.publish({
    channel : this._channelName,
    message : data
  });
};

PubnubService.prototype.disconnect = function( data ) {
  this.pubnub.unsubscribe({
    channel : this._channelName
  });
};