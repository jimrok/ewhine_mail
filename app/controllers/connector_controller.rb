require 'nokogiri'
require 'uri'
require 'cgi'
require 'net/http'
require 'net/https'
class ConnectorController < ApplicationController
	skip_before_filter :authenticate_user, :only => [:service]

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
				render :text=>"<a href='#{CONFIG[:host]}/register'>绑定邮箱</a>"
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
	begin
		api_url="#{CONFIG[:server_host]}/api/v1/conversations/ocu_messages"
		user_mail=params[:mail]||"user001@dehui220.com.cn,user002@dehui220.com.cn"
		title= "收到新邮件通知"
		subject=params[:subject]||"移动导入数据[附件]"
		from=params[:from]||"dinglb"
		mail_id=params[:mail_id]||"tencent_F898415192E4F207AF796CEE@qq.com"
		content=params[:content]||"哈哈，有了新的了吧。"
		description="<font color='black'>标题：</font><font color='green'>#{subject}</font><br><font color='black'>发件人：</font><font color='green'>#{from}</font><br><br>#{content}"
		article={article_count:1,articles:[{title:title,description:description,url:"#{CONFIG[:host]}/mails/show?mail_id=#{mail_id}"}]}
		timestamp = Time.now.to_i
		signed_url = hmacsha1(api_url + "?timestamp=#{timestamp}", CONFIG[:OcuKey])
		request = Typhoeus::Request.new(api_url,:body=>{:content_type=>1,:direct_to_user_ids=>user_mail,:body=>article.to_json},:method=>:post,:ssl_verifypeer=>false,:timeout=>20,:headers=>{'TIMESTAMP'=>timestamp,'AUTHORIZATION'=>"mac #{CONFIG[:OcuID]}:#{signed_url}"})


		request.on_complete do |response|

			if response.success?
				Rails.logger.info "Send to platform success."
				status=200
			elsif response.timed_out?
			          # aw hell no
			          Rails.logger.info "Send to platform timeout. mail:#{user_mail}"
			      elsif response.code == 0
			          # Could not get an http response, something's wrong.
			          Rails.logger.error "Send to platform error: code == 0  return body:#{response.body}"
			      else
			          # Received a non-successful http response.
			          Rails.logger.error("Send to platform error,http code:#{response.code.to_s} return:#{response.body}" )
			      end
			  end

			  request.run


			rescue Exception =>e
				Rails.logger.error "Send to platform  error:#{e.message}\n\n#{e.backtrace.join("\n")}"
			ensure
			end
			render :nothing => true,:status=>status
		end
	end
