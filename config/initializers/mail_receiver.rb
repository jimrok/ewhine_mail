require 'rubygems'
require 'rufus/scheduler'
include MailHelper
scheduler = Rufus::Scheduler.new

scheduler.every("60s") do
	receive_new_email
end