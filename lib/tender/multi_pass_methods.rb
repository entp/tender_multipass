module Tender
  module MultiPassMethods
    def tender_multipass(cookies, expires = nil)
      Tender::MultiPass.new(self).create(cookies, expires)
    end
  end
end