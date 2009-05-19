require File.join(File.dirname(__FILE__), 'test_helper')

class TenderMultipassTest < Test::Unit::TestCase
  def setup
    Tender::MultiPass.backend = :encrypted
    @user    = Tender::TestUser.new("seaguy@hero.com")
    @date    = 1234.seconds.from_now
    @cookies = {}
    @key     = EzCrypto::Key.with_password(Tender::MultiPass.support_domain, Tender::MultiPass.site_key)
  end

  def test_unencrypted_options_set
    actual = @user.tender_multipass_object.create_unencrypted_hash(:expires => @date)
    assert_equal({:expires => @date.to_s(:db), :email => @user.email}, actual)
  end
  
  def test_unencrypted_options_set_with_name
    actual = @user.tender_multipass_object.create_unencrypted_hash(:expires => @date, :name => 'bob')
    assert_equal({:expires => @date.to_s(:db), :email => @user.email, :display_name => 'bob'}, actual)
  end
  
  def test_unencrypted_options_set_with_custom_value
    actual = @user.tender_multipass_object.create_unencrypted_hash(:expires => @date, :name => 'bob', :foo => 'bar')
    assert_equal({:expires => @date.to_s(:db), :email => @user.email, :display_name => 'bob', :foo => 'bar'}, actual)
  end
  
  def test_unencrypted_options_set_with_name_and_display_name
    actual = @user.tender_multipass_object.create_unencrypted_hash(:expires => @date, :name => 'bob', :display_name => 'Bob')
    assert_equal({:expires => @date.to_s(:db), :email => @user.email, :display_name => 'Bob', :username => 'bob'}, actual)
  end
  
  def test_unencrypted_options_set_with_name_and_display_name_and_username
    actual = @user.tender_multipass_object.create_unencrypted_hash(:expires => @date, :name => 'FRED', :display_name => 'Bob', :username => 'bob')
    assert_equal({:expires => @date.to_s(:db), :email => @user.email, :display_name => 'Bob', :username => 'bob'}, actual)
  end
  
  def test_unencrypted_options_set_with_custom_email
    actual = @user.tender_multipass_object.create_unencrypted_hash(:expires => @date, :email => 'bob')
    assert_equal({:expires => @date.to_s(:db), :email => 'bob'}, actual)
  end
  
  def test_encrypted_options
    expected = {:expires => @date.to_s(:db), :email => @user.email, :display_name => 'Bob', :username => 'bob'}.to_json
    assert_equal @key.encrypt64(expected), @user.tender_multipass_object.create_encrypted_string(:expires => @date, :name => 'bob', :display_name => 'Bob')
  end

  def test_creates_cookie
    @user.tender_multipass(@cookies, :expires => @date, :display_name => 'Bob', :name => 'bob')
    
    actual = @key.decrypt64(@cookies[:sso_multipass][:value])
    actual = ActiveSupport::JSON.decode(actual)

    expected = {'expires' => @date.to_s(:db), 'email' => @user.email, 'display_name' => 'Bob', 'username' => 'bob'}

    assert_equal expected, actual
  end

  def test_validates_cookie
    options   = {'expires' => @date.to_s(:db), 'email' => @user.email, 'display_name' => 'Bob', 'username' => 'bob'}
    encrypted = @key.encrypt64(options.to_json)
    assert_equal options, @user.tender_multipass_object.valid?(encrypted)
  end

  def test_invalidates_bad_string
    assert_raises Tender::MultiPass::DecryptError do
      @user.tender_multipass_object.valid?("abc")
    end
  end

  def test_invalidates_bad_json
    assert_raises Tender::MultiPass::JSONError do
      @user.tender_multipass_object.valid?(@key.encrypt64("abc"))
    end
    assert_raises Tender::MultiPass::JSONError do
      @user.tender_multipass_object.valid?(@key.encrypt64("{a"))
    end
  end

  def test_invalidates_old_expiration
    options   = {'expires' => 1.second.ago.to_s(:db), 'email' => @user.email, 'display_name' => 'Bob', 'username' => 'bob'}
    encrypted = @key.encrypt64(options.to_json)
    assert_raises Tender::MultiPass::ExpiredError do
      @user.tender_multipass_object.valid?(encrypted)
    end
  end
end