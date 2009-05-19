require 'openssl'

module Tender
  class MultiPass
    class Invalid      < StandardError; end
    class ExpiredError < Invalid;       end
    class JSONError    < Invalid;       end
    class DecryptError < Invalid;       end

    class << self
      attr_accessor :site_key
      attr_accessor :support_domain
      attr_accessor :cookie_domain
      attr_accessor :backends
      attr_accessor :cookie_name

      # Defaults to the Encrypted backend if available
      def backend
        @backend ||= backends[:hash]
      end

      def backend=(value)
        value = @backends[value] if @backends.key?(value)
        @backend = value
      end
    end

    self.cookie_name = :sso_multipass

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
      options[:email] ||= @user.email
      if options[:name_field]
        options[:name] ||= @user.send(options[:name_field])
      end
      options.each do |key, value|
        cookies[:"tender_#{key}"] = cookie_value(value)
      end
      cookies[:tender_expires]   = cookie_value(expires)
      cookies[:tender_hash]      = cookie_value(expiring_token(expires, options))
      cookies
    end

    def expiring_token(expires, options = {})
      values = [self.class.superclass.support_domain, options[:email], expires, options[:name]]
      values.compact!
      generate_hmac(values * "/")
    end

    def expire(cookies)
      [:tender_email, :tender_expires, :tender_hash, :tender_name].each do |key|
        cookies.delete key, :domain => self.class.superclass.cookie_domain
      end
    end

  private
    def generate_hmac(string)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new("SHA1"), self.class.superclass.site_key, string)
    end
  end

  class EncryptedMultiPass < MultiPass
    def valid?(encrypted)
      json = crypto_key.decrypt64(encrypted)
      
      if json.nil?
        raise MultiPass::DecryptError
      end

      options = ActiveSupport::JSON.decode(json)
      
      if !options.is_a?(Hash) || options['expires'].blank?
        raise MultiPass::JSONError
      end

      if Time.now.utc > Time.parse(options['expires'])
        raise MultiPass::ExpiredError
      end

      options
    rescue ActiveSupport::JSON::ParseError
      raise MultiPass::JSONError
    end

    def create(cookies, options = {})
      name  = options.delete(:cookie_name) || self.class.superclass.cookie_name
      value = create_encrypted_string(options)
      cookies[name] = cookie_value(value)
    end

    def expire(cookies, options = {})
      name = options.delete(:cookie_name) || self.class.superclass.cookie_name
      cookies.delete name, :domain => self.class.superclass.cookie_domain
    end

    def create_encrypted_string(options = {})
      json = create_unencrypted_hash(options).to_json
      crypto_key.encrypt64(json)
    end

    # expires - a timestamp indicating the period this cookie is valid for 
    # username - this user's username 
    # email - email address for this user 
    # url - an url to view this user 
    # avatar_url - the url for this users avatar 
    # profile_url - an url to this user's profile 
    # display_name - a display name 
    # guid - a unique identifier 
    def create_unencrypted_hash(options = {})
      options[:expires] = case options[:expires]
        when Fixnum               then Time.at(options[:expires]).to_s(:db)
        when Time, DateTime, Date then options[:expires].to_s(:db)
        else options[:expires].to_s
      end
      options[:email] ||= @user.email

      # :name is a legacy Tender::MultiPass option.  Use it in place of 
      # :display_name or :username
      name = options.delete(:name)
      [:display_name, :username].detect do |key|
        if !options[key]
          options[key] = name
        end
      end unless name.blank?
      options
    end

  private
    def crypto_key
      @crypto_key ||= EzCrypto::Key.with_password(self.class.superclass.support_domain, self.class.superclass.site_key)
    end

    def cookie_value(value)
      { :value => value.to_s, :domain => self.class.superclass.cookie_domain }
    end
  end
end

Tender::MultiPass.backends = {:hash => Tender::HashedMultiPass}

begin
  gem 'ezcrypto'
  require 'ezcrypto'
  Tender::MultiPass.backends[:encrypted] = Tender::EncryptedMultiPass
rescue Gem::LoadError, LoadError
end