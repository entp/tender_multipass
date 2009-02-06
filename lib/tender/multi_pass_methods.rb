module Tender
  module MultiPassMethods
    def tender_multipass(cookies, expires = nil, name_field = nil)
      Tender::MultiPass.new(self).create(cookies, expires, name_field)
    end
  end
end