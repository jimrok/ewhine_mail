require 'redis'
require 'email'
require 'attachment'

$redis = Redis.new :host => '127.0.0.1', :db => 10 # default port : 6379

