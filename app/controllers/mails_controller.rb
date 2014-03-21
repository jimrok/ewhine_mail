require 'digest/md5'
require 'fileutils'

class MailsController < ApplicationController
	skip_before_filter :authenticate_user , :only => [:download]
	Expiration = 60*60*24
	def new
		@mail_id=params[:mail_id]
		@type=params[:type]||"0"
		@to=""
		if @mail_id && @mail_id.present? then
			object_s=$redis.get("mail:#{@mail_id}:object")
			if object_s then
				@mail=Marshal.load(object_s)
				@to="#{@mail.from_addrs.first};"
				@subject="Re:#{@mail.subject}"
				if @type== "2"	then
					original_to=@mail.from_addrs.concat(@mail.to_addrs)
					original_to.concat @mail.cc_addrs if @mail.cc_addrs
					@to=original_to.uniq.join(";")
				end
			else
				render :mail_not_found
				return
			end
		end
	end

	def create
		init_smtp
		mail_id=params[:mail_id]
		if mail_id.present? then
			object_s=$redis.get("mail:#{mail_id}:object")
			if object_s then
				mail=Marshal.load(object_s)
			end
			if mail.nil? then
				render :mail_not_found
				return
			end
			#拆解附件
			mail_root=mail_root(mail_id)
			extract_attachments mail_id
		end
		m_from=@from=session[:email]
		m_to=@to=params[:to]
		m_subject=@subject=params[:subject]
		m_content=@content=params[:content]
		m_cc=@cc=params[:cc]
		m_bcc=@bcc=params[:bcc]
		unless m_to.present? then
			@error="请输入收件人信息。"
			render :new	
			return
		end
		begin	
			Mail.deliver do
				from     m_from
				to       m_to
				subject  m_subject
				cc m_cc if  m_cc.present?
				bcc m_bcc if  m_bcc.present?
				html_part do
					content_type 'text/html; charset=UTF-8'
					if mail then
						body m_content+"<div>----以下是原始邮件---</div>"+mail.content
					else
						body m_content
					end
				end
				if mail_root && File.exist?( mail_root) then
					Dir.foreach(mail_root) do|filename|
						next if filename == '.' or filename == '..'
						add_file mail_root+filename 
					end
				end
			end
		rescue Exception=>e
			Rails.logger.error e
			@error="邮件发送错误，请检查您的数据并重试。"
			render :new
		ensure
		end
	end

	def show
		mail_id=params[:mail_id]
		object_s=$redis.get("mail:#{mail_id}:object")
		if object_s then
			@mail=Marshal.load(object_s)
		else
			server_mail= find_mail mail_id
			if(server_mail.nil?) then
				render :mail_not_found
				return
			end
			@mail=Email.new(server_mail)
			$redis.setex("mail:#{mail_id}:object",Expiration,Marshal.dump(@mail))
		end
	end
	def download
		mail_id=params[:mail_id]
		filename=URI.decode(params[:filename])
		att_path=mail_root(mail_id)+filename

		extract_attachments(mail_id) unless File.exist?(att_path)

		send_file att_path, :filename => filename

	end

	def extract_attachments mail_id
		mail_root_path= mail_root mail_id
		if(File.exist? mail_root_path) then
			return
		end
		FileUtils.mkdir_p(mail_root_path)
		mail = find_mail mail_id
		mail.attachments.each do|att|
			File.open( mail_root_path+att.filename , "w+b", 0644 ) { |f| f.write att.body.decoded }
		end
	end

	def find_mail id
		init_imap
		mail=Mail.find({:keys=>"HEADER Message-ID #{id}"}).first
		# mail=Mail.last
		mail
	end

	def mail_root mail_id
		"#{Rails.root}/content/#{Digest::MD5.hexdigest(mail_id)}/"
	end
end
