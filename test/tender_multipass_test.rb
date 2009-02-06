require File.join(File.dirname(__FILE__), 'test_helper')

module Tender
  class TestUser < Struct.new(:email, :name)
    include Tender::MultiPassMethods
  end

  MultiPass.site_key       = "abc"
  MultiPass.support_domain = "help.xoo.com"
  MultiPass.cookie_domain  = ".xoo.com"
end

class TenderMultipassTest < Test::Unit::TestCase
  def setup
    @user    = Tender::TestUser.new("seaguy@hero.com", "Joe Seaguy")
    @cookies = {}
    @user.tender_multipass(@cookies, 1234)
  end

  def test_tender_email_cookie_is_set
    assert_equal({:value => @user.email, :domain => Tender::MultiPass.cookie_domain}, @cookies[:tender_email])
  end

  def test_tender_expires_cookie_is_set
    assert_equal({:value => "1234", :domain => Tender::MultiPass.cookie_domain},      @cookies[:tender_expires])
  end
  
  def test_tender_name_not_required
    @user.tender_multipass(@cookies, 1234)
    @user = Tender::TestUser.new("seaguy@hero.com")
    assert_nil @cookies[:tender_name]
  end

  def test_tender_hash_cookie_is_set
    digest = OpenSSL::Digest::Digest.new("SHA1")
    hash   = OpenSSL::HMAC.hexdigest(digest, Tender::MultiPass.site_key, "#{Tender::MultiPass.support_domain}/#{@user.email}/1234")
    assert_equal @cookies[:tender_email], :value => @user.email, :domain => Tender::MultiPass.cookie_domain
  end
  
end

class TenderMultipassWithNameTest < Test::Unit::TestCase
  def setup
    @user    = Tender::TestUser.new("seaguy@hero.com", "Sea Guy")
    @cookies = {}
    @user.tender_multipass(@cookies, 1234, :name)
  end

  def test_tender_name_is_set
    assert_equal({ :value => "Sea Guy", :domain => Tender::MultiPass.cookie_domain }, @cookies[:tender_name])
  end

  
  def test_tender_hash_cookie_is_set
    digest = OpenSSL::Digest::Digest.new("SHA1")
    hash   = OpenSSL::HMAC.hexdigest(digest, Tender::MultiPass.site_key, "#{Tender::MultiPass.support_domain}/#{@user.email}/1234/Sea Guy")
    assert_equal @cookies[:tender_email], :value => @user.email, :domain => Tender::MultiPass.cookie_domain
  end
end
