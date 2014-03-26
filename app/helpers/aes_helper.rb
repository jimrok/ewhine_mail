module AesHelper

  def encrypt(data)
    cipher = OpenSSL::Cipher::AES.new(128, :CBC)
    cipher.encrypt
    cipher.key = "c351bfd05dab20d7"
    cipher.iv = "a0fe7c7c98e09e8c"
    encrypted = ""
    encrypted << cipher.update(data)
    encrypted << cipher.final
    hex_string = encrypted.unpack('H*').first
  end

  def decrypt(encrypted)
    decipher = OpenSSL::Cipher::AES.new(128, :CBC)
    decipher.decrypt
    decipher.key = "c351bfd05dab20d7"
    decipher.iv = "a0fe7c7c98e09e8c"
    bin_string = [encrypted].pack('H*')
    plain = "" 
    plain << decipher.update(bin_string)
    plain << decipher.final
  end

  def hmacsha1(data, key)
    Base64.encode64(OpenSSL::HMAC.digest('sha1',key, data)).strip!
  end
end