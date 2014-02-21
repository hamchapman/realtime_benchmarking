// (function() {
  
//   var pusherSubscriber = new Pusher('a8536d1bddd6f5951242', { authEndpoint: '/auth' });
//   var subscriberChannel = pusherSubscriber.subscribe('private-test-channel');

//   var pusherPublisher = new Pusher('a8536d1bddd6f5951242', { authEndpoint: '/auth' });
//   var publisherChannel = pusherPublisher.subscribe('private-test-channel');

//   subscriberChannel.bind('pusher:subscription_succeeded', function() {
//     subscriberChannel.bind('client-test', function(data) {
//       console.log("Pusher event received");
//     });
//   });

//   publisherChannel.bind('pusher:subscription_succeeded', function() {
//     var data = { text: "testing pusher", time: new Date()};
//     publisherChannel.trigger('client-test', data);
//   });    
// })();


function PusherService() {
  BenchmarkService.apply( this, arguments );
  
  // TODO: comment out before running tests
  // var self = this;
  // Pusher.log = function( msg ) {
  //     self._log( msg );
  // };
  
  this.name = 'Pusher';
  
  this._subscriptionCount = 0;
  
  var self = this;
  
  // The sender of a client event does not receive it.
  // So we need two Pusher instances
  this._pusherSubscriber = new Pusher( 'a8536d1bddd6f5951242' );
  this._subscriberChannel = this._pusherSubscriber.subscribe( this._channelName );
  this._subscriberChannel.bind( 'pusher:subscription_succeeded', function() {
      self._subscriptionSucceeded();
  });
  this._subscriberChannel.bind( 'client-event', function( message ) {
      console.log( message );
      // self._onMessage( message );
  });
  
  this._pusherPublisher = new Pusher( 'a8536d1bddd6f5951242' );
  this._publisherChannel = this._pusherPublisher.subscribe( this._channelName );
  this._publisherChannel.bind( 'pusher:subscription_succeeded', function() {
      self._subscriptionSucceeded();
  });
}
PusherService.prototype = new BenchmarkService;

PusherService.prototype._subscriptionSucceeded = function() {
  ++this._subscriptionCount;
  if( this._subscriptionCount === 2) {
      // this._onReady();
  }
};

PusherService.prototype.send = function( data ) {
  this._publisherChannel.trigger( 'client-event', data );
};

PusherService.prototype.disconnect = function() {
  this._pusherSubscriber.disconnect();
  this._pusherPublisher.disconnect();
};