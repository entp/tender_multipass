path = File.join(File.dirname(__FILE__), '..', '..', '..', 'config', 'initializers', 'tender_multi_pass.rb')
if !File.exist?(path)
  ruby_codes = <<-RUBY
Tender::MultiPass.class_eval do
  # Fill these with real values.
  # See http://help.tenderapp.com/faqs/setup-installation/login-from-cookies for more info
  #
  # self.site_key       = "abc" # Found in your Tender site settings
  # self.support_domain = "help.xoo.com" # custom domain
  # self.cookie_domain  = ".xoo.com"
end
RUBY

  open path, 'w' do |f|
    f.write ruby_codes.strip
  end
end