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
			return
		end
		#validate mail password
		begin
			init_imap  @email,password
			# config_hash=CONFIG[:imap]
			# imap = Net::IMAP.new(config_hash["address"], config_hash["port"], config_hash["enable_ssl"], nil, false)
			# imap.authenticate('LOGIN', @email,password)
			Mail.first
			# imap.login(@email,password)
			$redis.set("email:#{@email}:pass",password)
			session[:email]=@email
			session[:pass]=password
		rescue Exception=>e
			Rails.logger.error "login mail server   error:#{e.message}\n\n#{e.backtrace.join("\n")}"
		    @error="密码输入不正确，请重试。"
		    render :index
			return
        end
		@notice="绑定邮箱#{@email}成功。"
		render "common/success"
	end
	def rebind
		@email=params[:email]
			$redis.del("email:#{@email}:pass")
			render :index
	end
end
