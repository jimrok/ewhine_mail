# Load the rails application
require File.expand_path('../application', __FILE__)
require 'log4r'
include Log4r
# Initialize the rails application
EwhineMail::Application.initialize!

#Rails.logger = Log4r::Logger.new("mail_log")
