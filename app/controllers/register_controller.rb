require "net/imap"
class RegisterController < ApplicationController
	skip_before_filter :authenticate_user
	def index
		@email=params[:sso_key_value]	
		if ($redis.get("email:#{@email}:pass")) then
			render :rebind,  :email=>@email
		end
	end
	def create
		@email=params[:email]
		password=params[:password]
		if(password.empty?||@email.empty?) then
			@error="请输入密码。"
			render :index
		end
		#validate mail password
		begin
			config_hash=CONFIG[:imap]
			imap = Net::IMAP.new(config_hash["address"], config_hash["port"], config_hash["enable_ssl"], nil, false)
			imap.login(@email,password)
			$redis.set("email:#{@email}:pass",password)
			session[:email]=@email
			session[:pass]=password
		rescue Exception=>e
		    @error="密码输入不正确，请重试。"
		    render :index
		ensure
			 imap.disconnect if imap
		end
	end
	def rebind
		@email=params[:email]
			$redis.del("email:#{@email}:pass")
			render :index
	end
end
