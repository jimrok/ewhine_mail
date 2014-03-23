require 'rubygems'
require 'rufus/scheduler'
include MailHelper
scheduler = Rufus::Scheduler.new

scheduler.every("120s") do
	receive_new_email
end