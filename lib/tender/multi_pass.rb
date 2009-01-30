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
    def create(cookies, options = {})
      return nil if self.class.site_key.nil?
      expires = nil
      case options
        when Hash 
          expires = options.delete(:expires)
        else
          expires = options
          options = {}
      end
      expires = (expires || 1.week.from_now).to_i # we want unix time
      cookies[:tender_email]   = cookie_value(@user.email)
      cookies[:tender_expires] = cookie_value(expires)
      cookies[:tender_hash]    = cookie_value(expiring_token(expires))
      options.each do |key, value|
        cookies[:"tender_#{key}"] = cookie_value(value)
      end
      cookies
    end

    def expiring_token(expires)
      generate_hmac("#{self.class.support_domain}/#{@user.email}/#{expires}")
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