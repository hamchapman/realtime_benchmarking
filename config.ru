require 'rubygems'
require 'faye'
require File.join(File.dirname(__FILE__), 'app.rb')

use Faye::RackAdapter, :mount => '/faye', :timeout => 25
Faye::WebSocket.load_adapter('thin')

run CompetitorAnalysisTesting