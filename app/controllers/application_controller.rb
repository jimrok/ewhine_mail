require "mail_helper"

class ApplicationController < ActionController::Base
	before_filter :authenticate_user
	include MailHelper
	def authenticate_user
		if session[:email].nil? then
			if !check_url(params)	 then
				render :template => "common/session_timeout", :status => 401
			else
				email=session[:email]=params[:sso_key_value]
				pass=$redis.get("email:#{email}:pass")
				if pass then
					session[:pass]=pass
				else
					#还没有做过邮箱绑定
					@email=email
					render :template => "register/index"
				end
			end
		end
	end
	def check_url (hash)
		token=hash["token"]
		timestamp=hash["timestamp"]
		nonce=hash["nonce"]
		open_id=hash["open_id"]
		data = ""
	    data << timestamp.to_s
        data << nonce.to_s
		token =="#{CONFIG[:OcuID]}:#{hmacsha1(data, CONFIG[:OcuKey])}"
	end
	
end
