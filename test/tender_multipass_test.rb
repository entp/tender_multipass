require File.join(File.dirname(__FILE__), 'test_helper')

class TenderMultipassTest < Test::Unit::TestCase
  def setup
    Tender::MultiPass.backend = :hash
    @user    = Tender::TestUser.new("seaguy@hero.com")
    @cookies = {}
    @user.tender_multipass(@cookies, 1234)
  end

  def test_tender_email_cookie_is_set
    assert_equal @cookies[:tender_email], :value => @user.email, :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_email_custom_cookie_is_set
    @cookies = {}
    @user.tender_multipass(@cookies, :email => 'foo@bar.com')
    assert_equal @cookies[:tender_email], :value => 'foo@bar.com', :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_expires_cookie_is_set
    assert_equal @cookies[:tender_expires], :value => "1234", :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_hash_cookie_is_set
    digest = OpenSSL::Digest::Digest.new("SHA1")
    hash   = OpenSSL::HMAC.hexdigest(digest, Tender::MultiPass.site_key, "#{Tender::MultiPass.support_domain}/#{@user.email}/1234")
    assert_equal @cookies[:tender_hash], :value => hash, :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_hash_cookie_is_set_with_custom_email
    @cookies = {}
    @user.tender_multipass(@cookies, :expires => 1234, :email => "foo@bar.com")
    digest = OpenSSL::Digest::Digest.new("SHA1")
    hash   = OpenSSL::HMAC.hexdigest(digest, Tender::MultiPass.site_key, "#{Tender::MultiPass.support_domain}/foo@bar.com/1234")
    assert_equal @cookies[:tender_hash], :value => hash, :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_hash_cookie_is_set_with_name
    @cookies = {}
    @user.tender_multipass(@cookies, :expires => 1234, :name => 'jacob')
    digest = OpenSSL::Digest::Digest.new("SHA1")
    hash   = OpenSSL::HMAC.hexdigest(digest, Tender::MultiPass.site_key, "#{Tender::MultiPass.support_domain}/#{@user.email}/1234/jacob")
    assert_equal @cookies[:tender_hash], :value => hash, :domain => Tender::MultiPass.cookie_domain
  end
end

class TenderMultipassWithOptionsTest < Test::Unit::TestCase
  def setup
    Tender::MultiPass.backend = :hash
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
    Tender::MultiPass.backend = :hash
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

class TenderExpireTest < Test::Unit::TestCase
  def setup
    Tender::MultiPass.backend = :hash
    @user    = Tender::TestUser.new("seaguy@hero.com")
    @cookies = Tender::TestCookieJar.new 
    @user.tender_expire(@cookies)
  end

  def test_tender_email_cookie_is_cleared
    assert_equal @cookies.deleted_keys[:tender_email], :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_expires_cookie_is_cleared
    assert_equal @cookies.deleted_keys[:tender_expires], :domain => Tender::MultiPass.cookie_domain
  end

  def test_tender_hash_cookie_is_eaten
    assert_equal @cookies.deleted_keys[:tender_hash], :domain => Tender::MultiPass.cookie_domain
  end
end
