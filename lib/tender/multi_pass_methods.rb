module Tender
  module MultiPassMethods
    def tender_multipass(cookies, options = {})
      Tender::MultiPass.new(self).create(cookies, options)
    end
  end
end