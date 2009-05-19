$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require 'rubygems'
require 'test/unit'
require 'active_support'
require 'tender/multi_pass'
require 'tender/multi_pass_methods'
require 'cgi'

module Tender
  class TestUser < Struct.new(:email, :name)
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

  class TestCookieJar < Hash
    attr_reader :deleted_keys

    def delete(key, opts = {})
      @deleted_keys ||= {}
      @deleted_keys[key] = opts
    end
  end
end

class Test::Unit::TestCase
  def assert_cookie(cookie, expected)
    assert_equal expected, cookie
  end
end