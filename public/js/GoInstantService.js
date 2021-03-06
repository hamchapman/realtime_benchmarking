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
      self._onMessage( value );
    } );

    self._onReady();
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