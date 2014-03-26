include AesHelper
module MailHelper
	def hmacsha1(data, key)
		Base64.encode64(OpenSSL::HMAC.digest('sha1',key, data)).strip!
	end
	def mail_root mail_id
		"#{Rails.root}/contents/#{Digest::MD5.hexdigest(mail_id)}/"
	end
	def init_imap (name=nil,password=nil)
		email=name||session[:email]	
		pass=password||session[:pass]
		config_hash=CONFIG[:imap]
		config_hash.symbolize_keys!.merge!(:user_name=>email,:password=>pass)
		Mail.defaults do
			retriever_method :imap, config_hash
		end

	end

	def init_smtp
		email=session[:email]	
		pass=session[:pass]
		config_hash=CONFIG[:smtp]
		config_hash.symbolize_keys!.merge!(:user_name=>email,:password=>pass)
		p config_hash
		Mail.defaults do
			delivery_method :smtp, config_hash
		end
	end

	def send_ocu_message message
		success =false
		begin
			api_url="#{CONFIG[:server_host]}/api/v1/conversations/ocu_messages"
			user_mail=message[:users]
			title= "收到新邮件通知"
			subject=message[:subject]
			from=message[:from]
			mail_id=message[:mail_id]
			content=message[:content]
			content.strip!
			content=Nokogiri::HTML(content).text[0,200].gsub(/(\r|\n)+/m,"<br>")
			description="<font color='black'>标题：</font><font color='green'>#{subject}</font><br><font color='black'>发件人：</font><font color='green'>#{from}</font><br><br>#{content}"
			article={article_count:1,articles:[{title:title,description:description,url:"#{CONFIG[:host]}/ewhine_mail/mails/show?mail_id=#{mail_id}"}]}
			timestamp = Time.now.to_i
			signed_url = hmacsha1(api_url + "?timestamp=#{timestamp}", CONFIG[:OcuKey])
			request = Typhoeus::Request.new(api_url,:body=>{:content_type=>1,:direct_to_user_ids=>user_mail,:body=>article.to_json},:method=>:post,:ssl_verifypeer=>false,:timeout=>20,:headers=>{'TIMESTAMP'=>timestamp,'AUTHORIZATION'=>"mac #{CONFIG[:OcuID]}:#{signed_url}"})


			request.on_complete do |response|

				if response.success? 
					Rails.logger.info "Send to platform success."
					success=true
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
		success
	end

	def receive_new_email
		begin
			puts "start receive mail.time:#{Time.now}"
			init_imap CONFIG[:reminder_mail],AesHelper.decrypt(CONFIG[:reminder_password])
			emails=Mail.find({:delete_after_find=>true,:count=>50})
			emails.each do|email|
				m_mail=Email.new(email)
				$redis.setex("mail:#{m_mail.id}:object",MailsController::Expiration,Marshal.dump(m_mail))
				users=m_mail.to
				users.concat m_mail.cc if m_mail.cc.present?
				users.concat m_mail.bcc if m_mail.bcc.present?
				users.uniq.delete_if {|x| ((! x.end_with? CONFIG[:domain]) ||$redis.get("mail:#{x}:subscribed").nil?)} 
				if users.length>0 
					send_ocu_message ({:users=>users.uniq.join(","),:subject=>m_mail.subject+(m_mail.attachments.length>0 ? "[附件]":""),:mail_id=>m_mail.id,:from=>m_mail.from.first,:content=>m_mail.content})
				end
				mail_root_path= mail_root m_mail.id
				if(File.exist? mail_root_path) then
					return
				end
				FileUtils.mkdir_p(mail_root_path)
				email.attachments.each do|att|
					att_id=att.content_id
					File.open( mail_root_path+att_id.gsub(/[<>]/,"") , "w+b", 0644 ) { |f| f.write att.body.decoded }
				end
			end
		rescue Exception =>e
			Rails.logger.error "receive email  error:#{e.message}\n\n#{e.backtrace.join("\n")}"
		ensure
		end
	end

end

