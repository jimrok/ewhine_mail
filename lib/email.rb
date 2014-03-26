class Email
	attr_accessor :subject,:from,:from_addrs,:to,:to_addrs,:cc,:cc_addrs,:bcc,:bcc_addrs,:multipart,:attachments,:content,:date,:id
	def initialize mail 
		@id=mail.message_id
		@from=mail.from
		@from_addrs=mail[:from].addrs.map {|addr|addr.to_s}
		@cc=mail.cc
		@cc_addrs=mail[:cc].addrs.map {|addr|addr.to_s} if @cc
		@bcc=mail.bcc
		@bcc_addrs=mail[:bcc].addrs.map {|addr|addr.to_s} if @bcc
		@to=mail.to
		@to_addrs=mail[:to].addrs.map {|addr|addr.to_s}

		@multipart=mail.multipart?
		@date=mail.date
		@subject=mail.subject||"(无主题)"
		if mail.html_part then
			@content=mail.html_part.body.decoded.force_encoding("UTF-8")
		elsif mail.text_part then
			@content=mail.text_part.body.decoded.force_encoding("UTF-8")
		else
			@content=mail.body.decoded.force_encoding("UTF-8")
		end
		@content=@content.gsub(/\"cid:(.+?)\"/,'"/ewhine_mail/mails/images?att_id=\1&mail_id='+@id+'"');
		if mail.attachments.length then
			@attachments=[]
			mail.attachments.each do|att|
				attach=Attachment.new
				attach.filename=att.filename
				attach.id=att.content_id.gsub(/[<>]/,"");
				# att.content_disposition.match(/size=(\d+)/)
				attach.size=att.body.decoded.size
				@attachments<<attach
			end
		else
			@attachments=[]	
		end
	end
end