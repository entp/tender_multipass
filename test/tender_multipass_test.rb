require File.join(File.dirname(__FILE__), 'test_helper')

module Tender
  class TestUser < Struct.new(:email)
    include Tender::MultiPassMethods
  end

  class DefaultOptionUser < TestUser
    tender_multipass do |user|
      {:bar => 'foo'}
    end
  end

  MultiPass.site_key       = "abc"
  MultiPass.support_domain = "help.xoo.com"
  MultiPass.cookie_domain  = ".xoo.com"
end

class TenderMultipassTest < Test::Unit::TestCase
  def setup
    @user    = Tender::TestUser.new("seaguy@hero.com")
    @cookies = {}
    @user.tender_multipass(@cookies, 1234)
  end

  def test_tender_email_cookie_is_set
    assert_equal @cookies[:tender_email], :value => @user.email, :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_expires_cookie_is_set
    assert_equal @cookies[:tender_expires], :value => "1234", :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_hash_cookie_is_set
    digest = OpenSSL::Digest::Digest.new("SHA1")
    hash   = OpenSSL::HMAC.hexdigest(digest, Tender::MultiPass.site_key, "#{Tender::MultiPass.support_domain}/#{@user.email}/1234")
    assert_equal @cookies[:tender_email], :value => @user.email, :domain => Tender::MultiPass.cookie_domain
  end
end

class TenderMultipassWithOptionsTest < Test::Unit::TestCase
  def setup
    @user    = Tender::TestUser.new("seaguy@hero.com")
    @cookies = {}
    @user.tender_multipass(@cookies, :expires => 1234, :foo => 'bar')
  end

  def test_custom_tender_cookie_is_set
    assert_equal @cookies[:tender_foo], :value => 'bar', :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_email_cookie_is_set
    assert_equal @cookies[:tender_email], :value => @user.email, :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_expires_cookie_is_set
    assert_equal @cookies[:tender_expires], :value => "1234", :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_hash_cookie_is_set
    digest = OpenSSL::Digest::Digest.new("SHA1")
    hash   = OpenSSL::HMAC.hexdigest(digest, Tender::MultiPass.site_key, "#{Tender::MultiPass.support_domain}/#{@user.email}/1234")
    assert_equal @cookies[:tender_email], :value => @user.email, :domain => Tender::MultiPass.cookie_domain
  end
end

class TenderMultipassWithDefaultOptionsTest < Test::Unit::TestCase
  def setup
    @user    = Tender::DefaultOptionUser.new("seaguy@hero.com")
    @cookies = {}
    @user.tender_multipass(@cookies, :expires => 1234)
  end

  def test_default_tender_cookie_is_set
    assert_equal @cookies[:tender_bar], :value => 'foo', :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_email_cookie_is_set
    assert_equal @cookies[:tender_email], :value => @user.email, :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_expires_cookie_is_set
    assert_equal @cookies[:tender_expires], :value => "1234", :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_hash_cookie_is_set
    digest = OpenSSL::Digest::Digest.new("SHA1")
    hash   = OpenSSL::HMAC.hexdigest(digest, Tender::MultiPass.site_key, "#{Tender::MultiPass.support_domain}/#{@user.email}/1234")
    assert_equal @cookies[:tender_email], :value => @user.email, :domain => Tender::MultiPass.cookie_domain
  end
end
