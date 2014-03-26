require 'rubygems'
require 'rufus/scheduler'
include MailHelper
scheduler = Rufus::Scheduler.new(:lockfile => ".rufus-scheduler.lock")

scheduler.every("60") do
	receive_new_email
end

# scheduler.join