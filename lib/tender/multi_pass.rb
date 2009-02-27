require 'openssl'

module Tender
  class MultiPass
    class << self
      attr_accessor :site_key
      attr_accessor :support_domain
      attr_accessor :cookie_domain
    end

    attr_reader :user

    def initialize(user)
      @user = user
    end

    # Sets tender cookie values on the given cookie jar.
    def create(cookies, expires = nil, name_field = nil)
      return nil if self.class.site_key.nil?
      expires = (expires || 1.week.from_now).to_i # we want unix time
      cookies[:tender_email]   = cookie_value(@user.email)
      cookies[:tender_expires] = cookie_value(expires)
      if name_field
        name_field             = @user.send(name_field)
        cookies[:tender_name]  = cookie_value(name_field)
      end
      cookies[:tender_hash]    = cookie_value(expiring_token(expires, name_field))
      cookies
    end

    def expiring_token(expires, name_field=nil)
      generate_hmac([self.class.support_domain, @user.email, expires, name_field].compact.join("/"))
    end

  protected
    def cookie_value(value)
      { :value => value.to_s, :domain => self.class.cookie_domain }
    end

    def generate_hmac(string)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new("SHA1"), self.class.site_key, string)
    end
  end
end