module Tender
  module MultiPassMethods
    def tender_multipass(cookies, expires = nil)
      Tender::MultiPass.new(self).create(cookies, expires)
    end

    def tender_expire(cookies)
      Tender::MultiPass.new(self).expire(cookies)
    end
  end
end
