require "net/imap"
require "mail"

imap = Net::IMAP.new("mail.dehui220.com.cn", 993, true, nil, false)
imap.login("user002@dehui220.com.cn","1qaz2WSX")
imap.select("inbox")
uids = imap.uid_search("HEADER Message-ID tencent_B9892D10C828B330ABA8B5ED")
request,part = 'BODY.PEEK[]','BODY[]'
result = imap.uid_fetch(uids, request)[0].attr[part]
mail=Mail.new result
p mail.inspect
# envelope = result.attr["ENVELOPE"]
# body = result.attr["BODY"]
# p envelope.inspect
# p 111111
# p body.inspect
# envelope.parts.each do|e|
# 	if e.media_type=="TEXT" then
# 	end
# end
