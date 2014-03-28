# -*- coding: utf-8 -*-
# Set your full path to application.
app_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))
 
# Set rainbows options
worker_processes 2
preload_app true
timeout 180
listen 3001
 
# Spawn rainbows master worker for user apps (group: apps)
# user 'apps', 'apps'
 
# Fill path to your app
working_directory app_path
 
# Should be 'production' by default, otherwise use other env
rails_env = ENV['RAILS_ENV'] || 'production'
 
# Log everything to one file
stderr_path 'log/rainbows.log'
stdout_path 'log/rainbows.log'
 
# Set master PID location
pid "#{app_path}/tmp/pids/rainbows.pid"

# Enable copy on write friendly GC for rubies that have it as an option (2.0.0dev etc)
GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true

 
before_fork do |server, worker|
  #ActiveRecord::Base.connection.disconnect!
  $redis.quit
 
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end

end
 
after_fork do |server, worker|

  Redis.current.client.reconnect
  #ActiveRecord::Base.establish_connection
  
end
 
Rainbows! do
  use :EventMachine
  worker_connections 200
  client_max_body_size 500*1024*1024
end