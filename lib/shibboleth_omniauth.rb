require 'omniauth/core'
module OmniAuth
  module Strategies
    class Shibboleth
      include OmniAuth::Strategy

      attr_accessor :base_url, :entity_id

      #receive and save any needed parameters for the strategy
      def initialize(app, base_url, entity_id, options = {})
        self.base_url = base_url
        self.entity_id = entity_id
        super(app, :shibboleth, options)
      end

      #redirect to shibboleth login
      def request_phase
        r = Rack::Response.new
        r.redirect shibboleth_login_url
        r.finish
      end

      #check to see if we have a successful authentication
      def callback_phase
        if remote_user
          super
        else
          fail!('No REMOTE_USER from shibboleth authentication')
        end
      end

      def auth_hash
        OmniAuth::Utils.deep_merge(super, {
            'user_info' => {'email' => remote_user},
            'uid' => remote_user
        })
      end

      protected

      def shibboleth_login_url
        url = self.base_url
        return "#{url}?target=#{shibboleth_target()}&entityID=#{shibboleth_entity_id}"
      end

      def shibboleth_target
        root = URI.parse($APPLICATION_URL)
        root.scheme = 'https'
        root.merge!('/auth/shibboleth/callback')
        CGI.escape(root.to_s)
      end

      def shibboleth_entity_id
        return CGI.escape(self.entity_id)
      end

      def remote_user
        shibboleth_attribute("REMOTE_USER")
      end

      #Do this in a way that (I think) will work with the attribute passed either by environment variables or header
      def shibboleth_attribute(name)
        [request.env[name.to_s], request.env["HTTP_#{name.to_s.upcase.gsub('-', '_')}"]].detect { |att| att.present? }
      end


    end

  end
end
