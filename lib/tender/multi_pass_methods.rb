module Tender
  module MultiPassMethods
    module ClassMethods
      def tender_multipass(&block)
        block ? @tender_multipass = block : @tender_multipass
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end

    def tender_multipass(cookies, options = nil, name_field = nil)
      default_options = \
        if multipass = self.class.tender_multipass
          multipass.call(self)
        else
          {}
        end

      if !options.is_a?(Hash)
        options = {:expires => options}
      end

      Tender::MultiPass.new(self).create(cookies, default_options.merge(options), name_field)
    end

    def tender_expire(cookies)
      Tender::MultiPass.new(self).expire(cookies)
    end
  end
end
