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
      raise NotImplementedError
    end

    def expire(cookies)
      raise NotImplementedError
    end

  private
    def cookie_value(value)
      { :value => value.to_s, :domain => self.class.superclass.cookie_domain }
    end
  end

  # Creates a separate cookie for each Tender variable.  The required ones are:
  #
  # * email
  # * expires - an integer of when this tender cookie expires in unix time
  # * hash - a SHA HMAC hash of "support_domain/email/expires"
  #
  # You can set custom values too.  They'll all get added as tender_* cookies.
  class HashedMultiPass < MultiPass
    # Sets tender cookie values on the given cookie jar.
    def create(cookies, options = {})
      return nil if self.class.superclass.site_key.nil?
      expires = (options.delete(:expires) || 1.week.from_now).to_i
      cookies[:tender_email]   = cookie_value(@user.email)
      cookies[:tender_expires] = cookie_value(expires)
      cookies[:tender_hash]    = cookie_value(expiring_token(expires))
      options.each do |key, value|
        cookies[:"tender_#{key}"] = cookie_value(value)
      end
      cookies
    end

    def expiring_token(expires)
      generate_hmac("#{self.class.superclass.support_domain}/#{@user.email}/#{expires}")
    end

    def expire(cookies)
      [:tender_email, :tender_expires, :tender_hash].each do |key|
        cookies.delete key, :domain => self.class.superclass.cookie_domain
      end
    end

  private
    def generate_hmac(string)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new("SHA1"), self.class.superclass.site_key, string)
    end
  end
end
