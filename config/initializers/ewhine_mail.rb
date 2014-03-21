require 'redis'
require 'email'
require 'attachment'

$redis = Redis.new :host => '127.0.0.1', :db => 10 # default port : 6379

if Rails.env.production? then
  redis_conn = proc {
    $redis
  }

  Sidekiq.configure_client do |config|
    config.redis = ConnectionPool.new(size: 20, &redis_conn)
  end

  # Sidekiq.configure_server do |config|
  #   config.redis = ConnectionPool.new(size: 20, &redis_conn)
  # end

end