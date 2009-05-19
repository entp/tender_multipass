module Tender
  module MultiPassMethods
    module ClassMethods
      # Define default Tender options for all cookies.  Anything ending in *_url
      # is changed to a URL when displayed in Tender
      #
      #   class User < ActiveRecord::Base
      #     include Tender::MultiPassMethods
      #
      #     tender_multipass do |user|
      #       {:external_url => "http://myapp.com/admin/users/#{user.id}",
      #        :plan        => user.plan.name}
      #     end
      #   end
      #
      def tender_multipass(&block)
        block ? @tender_multipass = block : @tender_multipass
      end

      # Points to the Tender::MultiPass class that implements the cookie format.
      def tender_multipass_class
        @tender_multipass_class ||= Tender::HashedMultiPass
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end

    # Modifies the given cookie jar with a Tender cookie.  Pass any of the given options
    # as custom options to add to the cookie.
    def tender_multipass(cookies, options = {})
      if !options.is_a?(Hash)
        options = {:expires => options}
      end

      tender_multipass_object.create(cookies, tender_default_options.merge(options))
    end

    # Expires the Tender cookie using the given cookie jar.
    def tender_expire(cookies)
      tender_multipass_object.expire(cookies)
    end

    # Points to an instance of the Tender::MultiPass object for this record.
    def tender_multipass_object
      @tender_multipass_object ||= self.class.tender_multipass_class.new(self)
    end

    # Points to a hash of the default Tender::MultiPass options.  Call the 
    # #tender_multipass class method (see above) to change this.
    def tender_default_options
      @tender_default_options ||= \
        if multipass = self.class.tender_multipass
          multipass.call(self)
        else
          {}
        end
    end
  end
end
