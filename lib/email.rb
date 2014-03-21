class Email
	attr_accessor :subject,:from,:from_addrs,:to,:to_addrs,:cc,:cc_addrs,:multipart,:attachments,:content,:date,:id
	def initialize mail 
		@id=mail.message_id
		@from=mail.from
		@from_addrs=mail[:from].addrs.map {|addr|addr.to_s}
		@cc=mail.cc
		@cc_addrs==mail[:cc].addrs.map {|addr|addr.to_s} if @cc
		@to=mail.to
		@to_addrs=mail[:to].addrs.map {|addr|addr.to_s}

		@multipart=mail.multipart?
		@date=mail.date
		@subject=mail.subject
		if mail.html_part then
			@content=mail.html_part.body.decoded.force_encoding("UTF-8")
		elsif mail.text_part then
			@content=mail.text_part.body.decoded.force_encoding("UTF-8")
		else
			@content=mail.body.decoded.force_encoding("UTF-8")
		end
		if mail.attachments.length then
			@attachments=[]
			mail.attachments.each do|att|
				attach=Attachment.new
				attach.filename=att.filename
				attach.id=att.content_id
				# att.content_disposition.match(/size=(\d+)/)
				attach.size=att.body.decoded.size
				@attachments<<attach
			end
		else
			@attachments=[]	
		end
	end
end