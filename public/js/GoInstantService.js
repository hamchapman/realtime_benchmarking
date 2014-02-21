// (function() {

//   var url = 'https://goinstant.net/cd2b44835134/analysis';
//   var connection = new goinstant.Connection(url);

  // connection.connect(function (err) {
  //   if (err) {
  //     console.log(err);
  //     return;
  //   }

  //   var benchmark = connection.room('benchmark');

  //   benchmark.join(function(err) {
  //     if (err) {
  //       console.log(err);
  //       return;
  //     }

  //     channel = benchmark.channel('channel');

  //     channel.on('message', {local: true}, function(msg) {
  //       console.log("GI message received");
  //     });

  //     channel.message({ time: Date.now(), msg: 'hi'}, function(err) {
  //       if (err) {
  //         console.log(err);
  //       }
  //       console.log("GI success");

  //     });
  //   });
  // });
// })();


function GoInstantService() {
  var self = this;
  BenchmarkService.apply( self, arguments );

  self.name = 'GoInstant';

  self.connectUrl = 'https://goinstant.net/cd2b44835134/analysis';

  self.connection = null;
  self.benchmark = null;
    
  goinstant.connect( self.connectUrl, function (err, connection, lobby ) {
    if (err) {
      throw err;
    }

    self.connection = connection;
    self.benchmark = lobby.key( '/analysis' );

    self.benchmark.on( 'set', { local: true }, function( value, context ) {
      console.log(value);
      // self._onMessage( value );
    } );

    // self._onReady();
  } );
}
GoInstantService.prototype = new BenchmarkService;

GoInstantService.prototype._handleResponse = function( err, msg, context ) {
  if( err ) {
    throw err;
  }
};

GoInstantService.prototype.send = function( message ) {
  this.benchmark.set( message );
};

GoInstantService.prototype.disconnect = function() {
  this.connection.disconnect();
};