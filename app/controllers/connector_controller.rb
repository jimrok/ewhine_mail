require 'nokogiri'
require 'uri'
require 'cgi'
require 'net/http'
require 'net/https'
class ConnectorController < ApplicationController
	skip_before_filter :authenticate_user

	def service
		if !check_url(request.headers)
			render :nothing => true  
			logger.error "request url not valid."
			return
		end
		doc=Nokogiri::XML(request.body.read)
		msg_type = doc.xpath('//xml/MsgType').first.text
		mail=doc.xpath('//xml/SSOKeyValue').first.text
		case msg_type
		when "text"
			content=doc.xpath('//xml/Content').first.text
			p "received text:#{content}"
		when "event"
			event_type=doc.xpath('//xml/Event').first.text
			if event_type=="subscribe" then
				$redis.set("mail:#{mail}:subscribed",1)
				render :text=>"绑定邮箱#{CONFIG[:host]}/ewhine_mail/register?sso_key_value=#{mail}"
				return
			elsif event_type=="unsubscribe" then
				$redis.del("mail:#{mail}:subscribed")
			end
		else
		end
		render :nothing => true
	end

	def publish

	#need check auth
	status=400


	render :nothing => true,:status=>status
end
##收取邮件，可以改为定时收取
def receive
	receive_new_email
	render :nothing => true,:status=>200
end

end

